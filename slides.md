% 🐍 🐳 w/ Docker w/ Security in Mind
% Nahuel Defossé (@D3f0)
% June 2019

----

# Goals

Be able to create a Python application with Docker,
with a *reasonable security level by default*.

Structure project for docker.

----

# Virtualization Basics

- Virtual Machines
- Hypervisors
- Operating System Level Virtualization/Isolation

----

## Virtual Machines

- Hard Disk images take big space (GBs)
- Boot up times are in the order of minutes
- Allocate a fixed amount of RAM (can be GBs)
- Are not so easy to distribute
  - i.e.: ISOs are not virtual Machines
  - Vagrant Boxes are not easy to distribute

----

### VMs Strengths

- Can run any Operating System
- Provide good isolation
- Mature technology
- Widely available

----

## Hypervisor

- Software/Firmware/Hardware that creates/runs VMs.
- Abstract the real resources from the VM

----

- Classified as:
  - Native (Level 1)
    - Xen, Oracle VM Server, Hyper-V, VMWare ESX/ESXi
  - Hosted (Level 2)
    - VMWare Workstation/Player, VMWare, Parallels, QEMU

----

- Linux KVM and BSD bhyve fall between the L1 and L2
  - Implemented as kernel modules


----

## OS Virtualization/Isolation

- LXC
- BSD Jails
- Solaris Zones
- Open Private Server (OpenVZ)
- **Docker** containers

----

# Containers

----

![](imgs/uo.png)

----

- Have a small disk footprint
- Use less RAM than a real VM
- Only provide *one service* 🤔
- Can be started in seconds

----

## Docker

----


![Docker Interfaces w/ 🐧Kernel](imgs/namespaces.png)

----

### Running an image

Running a well known web server docker image.

```bash
docker run --name my_container nginx -p 80:80
```

... prduces:

```
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
fc7181108d40: Pull complete
c4277fc40ec2: Pull complete
780053e98559: Pull complete
Digest: sha256:bdbf36b7f1f77ffe7bd2a32e59235dff6ecf131e3b6b5b96061c652f30685f3a
Status: Downloaded newer image for nginx:latest
```

----

Now we can browser [http://localhost:80](http://localhost:80)

----

## What just happened?

- Docker pulled the image from the public registry `hub.docker.com`
- A container was created with a random name
- That container was started
- The host machine port 80 was mapped to the container's 80

----

### Inspecting the container

We're root

```
$ docker exec my_container id
uid=0(root) gid=0(root) groups=0(root)
```

Which processes are present?

```
 docker exec my_container ps
OCI runtime exec failed: exec failed: container_linux.go:344: starting container process caused "exec: \"ps\": executable file not found in $PATH": unknown`
```

----

This image does not include **ps**.

It's a good practice only include the minimal elements for you application to run.

Less attack surface and smaller image sizes.

----

### Let's check Python image

[https://hub.docker.com/_/python](https://hub.docker.com/_/python)

----

```bash
docker run --name my_py_img --tty --interactive ipython:3.7

Python 3.7.2 (default, Feb  6 2019, 12:04:03)
[GCC 6.3.0 20170516] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import os
>>> os.system('ps')
  PID TTY          TIME CMD
    1 pts/0    00:00:00 python3
    6 pts/0    00:00:00 sh
    7 pts/0    00:00:00 ps
0
>>>
```

----

## 🤨

This image seems to have more things than `ps`.

```
$ docker images python:3.7
REPOSITORY    TAG    IMAGE ID       CREATED        SIZE
python        3.7    338b34a7555c   4 months ago   927MB
```


```bash
$ docker run --rm python:3.7 gcc
gcc: fatal error: no input files
compilation terminated.
```

----

## 🤨

### This image is bing enough to have a full Linux distro

Probably it's not the best thing to ship ⛵️

----

We need a way to reduce the size of our images, thus our containers.

But first we need to understand how storage works in a container.

----

### Container Storage

----

#### Images 📦

- Docker **images** are the base file system that the container
will see at runtime.

- **Images** is composed of layers 🍰, and will be created from
either a tar-file or building a Dockerfile.

----

#### Layers 🍰

![](imgs/layers.png)


----

#### We can actually look at layers...

```bash
docker history python:3.7 --no-trunc

IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
338b34a7555c        4 months ago        /bin/sh -c #(nop)  CMD ["python3"]              0B
<missing>           4 months ago        /bin/sh -c set -ex;   wget -O get-pip.py 'ht…   6.04MB
<missing>           4 months ago        /bin/sh -c #(nop)  ENV PYTHON_PIP_VERSION=19…   0B
<missing>           4 months ago        /bin/sh -c cd /usr/local/bin  && ln -s idle3…   32B
<missing>           4 months ago        /bin/sh -c set -ex   && wget -O python.tar.x…   70.3MB
<missing>           4 months ago        /bin/sh -c #(nop)  ENV PYTHON_VERSION=3.7.2     0B
<missing>           4 months ago        /bin/sh -c #(nop)  ENV GPG_KEY=0D96DF4D4110E…   0B
<missing>           4 months ago        /bin/sh -c apt-get update && apt-get install…   17MB
<missing>           4 months ago        /bin/sh -c #(nop)  ENV LANG=C.UTF-8             0B
<missing>           4 months ago        /bin/sh -c #(nop)  ENV PATH=/usr/local/bin:/…   0B
<missing>           4 months ago        /bin/sh -c set -ex;  apt-get update;  apt-ge…   560MB
<missing>           4 months ago        /bin/sh -c apt-get update && apt-get install…   142MB
<missing>           4 months ago        /bin/sh -c set -ex;  if ! command -v gpg > /…   7.81MB
<missing>           4 months ago        /bin/sh -c apt-get update && apt-get install…   23.2MB
<missing>           4 months ago        /bin/sh -c #(nop)  CMD ["bash"]                 0B
<missing>           4 months ago        /bin/sh -c #(nop) ADD file:4fec879fdca802d69…   101MB
```

----

### Container storage

- When the process writes to the filesystem, a new layer is produced.
- It's kept during the lifetime of the container.
- Changes are lost when the container is removed.

The good news is that all containers share the image, and won't take
space, unless they write

----

#### Volumes

- To overcome the problem of transient storage docker provides volumes.
- Types of volumes:
  - **un-named** when we define the exact place where files are stored

    **Must be absolute 🌡**
  - **named** when we let the Docker Engine define where our files will go.

----

```bash
$ docker run --rm -ti -v $(pwd):/code python:3.7 bash
root@d2b4492f3aa8:/# cd /code/
root@d2b4492f3aa8:/code# ls
root@d2b4492f3aa8:/code# touch main.py
root@d2b4492f3aa8:/code# exit
```

```bash
$ ls -ls
total 0
0 -rw-r--r-- 1 root root 0 Jun 14 16:59 main.py
```

----

Wait, weren't we **`uid=0`**? 🔥

----

# Network
