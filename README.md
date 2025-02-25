# Workshop 2: Machine Learning in Forest Modeling
 
Welcome to this workshop's repository. Here you'll find the code tutorials we will run during the workshop. For convenience, you can find the actual markdown documents inside the `src` folder, while the `html` folder contains the rendered documents for easier readability.

To get started, clone this repository to your local workstation. You can do that with the following:

```{shell}
git clone https://github.com/ttrotto/EDI-HPC.git
```

## Python

Next, for Python users you should be able to prepare an environment to install the dependencies in `requirements.txt`. You can do that with `pip`:

### Linux 

```{shell}
# create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# install pip
python3 -m pip install --upgrade pip

# install dependencies
python3 -m pip install -r requirements.txt
```

### Windows

```{shell}
# create virtual environment
py -m venv .venv
.venv\Scripts\activate

# install pip
py -m pip install --upgrade pip

# install dependencies
py -m pip install -r requirements.txt
```

Note that we do not provide dependencies for the tutorial on distributed workloads as many don't have access to HPC clusters. In case you do, you can also install `dask` and `dask-jobqueue` 

## R
Similarly, in R you would need to install a series of packages. You can do that with the following:

```{shell}
# code here
```

Have fun coding!
