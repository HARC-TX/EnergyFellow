# Energy Fellow Software Tool

## Introduction

The **Energy Fellow Software Tool** is an online platform designed to simplify and enhance feasibility analysis for District Energy (DE) systems and multi-building microgrids. Developed by the **Houston Advanced Research Center** in collaboration with the **University of Houston** and **Fugro**, and funded by the **Department of Energy**, the tool aims to:

- Reduce costs and engineering barriers.
- Provide advanced assessments using GIS capabilities and downscaled climate models.
- Utilize AI to benchmark solutions and analyze economic outcomes.

By making feasibility studies more accessible, the tool promotes the adoption of DE systems, which improve cost efficiency, resilience, and decarbonization efforts.

The tool is implemented online and accessible at **[energyfellow.com](http://energyfellow.com)**.

---

## Usage

Run the tool within the main folder with the input JSON file located in `main/userInput`:
```MATLAB
main('[user id]', '[parameter name]', '[value]')

```
Output results will be stored in `main/results_output`.

## System Requirements and Licenses

To run the **Energy Fellow Software Tool**, ensure your system meets the following requirements and has the necessary licenses installed:


## System Requirements and Licenses

To run the **Energy Fellow Software Tool**, ensure your system meets the following requirements and has the necessary licenses installed:

### System Requirements

- **Operating System**: Windows, macOS, or Linux (compatible with MATLAB).
- **MATLAB Version**: R2021a or later.
- **Processor**: Multi-core processor recommended for parallel computing.
- **Memory**: At least 8 GB of RAM (16 GB or more recommended for larger computations).
- **Disk Space**: 2 GB of free disk space for installation and data storage.

### Required Licenses

The following MATLAB toolboxes are required:

- **MATLAB**: Core platform for running the tool.
- **Statistics and Machine Learning Toolbox**: For advanced data analysis and statistical modeling.
- **Financial Toolbox**: For economic outcome analysis.
- **Parallel Computing Toolbox** *(optional)*: Recommended for enabling parallel computations to reduce calculation time.

---

## Parameters

The tool supports the following parameters:

1. **`logLevel`**: Logging level (`error`=default, `debug`=detailed).  
2. **`skipMode`**: Skip computations (`false`=default, `true`=use mock values).  
3. **`parallel`**: Enable parallelization (`false`=default, `true`=enabled, `<n>`=number of workers).  
4. **`ga`**: Genetic algorithm parameters (default integrated).

---

## Sample Files

To help users get started, a sample JSON file is provided:

### Microgrid Example
   - File ID: `caab2c2a-de7d-b699-d503-23d8b2113891`

