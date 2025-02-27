# Workshop 2: Machine Learning in Forest Modeling
 
Welcome to this workshop's repository. Here you'll find the code tutorials we will run during the workshop.

To get started, clone this repository to your local workstation. You can do that with the following:

```{shell}
git clone https://github.com/ttrotto/EDI-HPC.git
```

## Content
The folder structure of this repository is as follows:

```
.
├── enm
│   ├── data processed
│   ├── data raw
│   ├── model_outputs
│   ├── models
│   └── script
└── python
    ├── data
    ├── html
    └── img
```

The `enm` folder contains the R tutorials on Ecological Niche Modeling using supervised learning techniques (available from the `script` folder), while the `python` folder contains the code for the unsupervised learning and distributed computing tutorials. For the Python tutorials, the `html` folder contains the rendered markdowns for easier readability.

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

Note that we do not provide dependencies for the tutorial on distributed workloads as many don't have access to HPC clusters. In case you do, you can also install `dask`, `dask-ml`, and `dask-jobqueue` 

## R
Similarly, in R you would need to install a series of packages. You can do that with the following:

```{shell}
source("install_dependencies.R")
```

Have fun coding!