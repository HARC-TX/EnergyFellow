# Energy Fellow Software Tool

## Introduction

The **Energy Fellow Software Tool** is an online platform designed to simplify and enhance feasibility analysis for District Energy (DE) systems and multi-building microgrids. Developed by **Houston Advanced Reasearch Center** in collaboration with **University of Houston** and **Fugro**, and funded by the **Department of Energy**, the tool aims to:
- Reduce costs and engineering barriers.
- Provide advanced assessments using GIS capabilities and downscaled climate models.
- Utilize AI to benchmark solutions and analyze economic outcomes.

By making feasibility studies accessible, the tool promotes the adoption of DE systems, which improve cost efficiency, resilience, and decarbonization.

This project has been implemented online and is accessible at **[energyfellow.com](http://energyfellow.com)**.

---

## Usage

Run the tool with:
```MATLAB
main('[user id]', '[parameter name]', '[value]')
```

## Parameters

1. **`devMode`**: Environment (`false`=prod, `dev`/`true`=localhost, `local`=local files).  
2. **`logLevel`**: Logs (`error`=default, `debug`=detailed).  
3. **`skipMode`**: Skip computations (`false`=default, `true`=mock values).  
4. **`host`**: Production host (default: `amo-com`).  
5. **`port`**: Production port (default: `8888`).  
6. **`parallel`**: Parallelization (`false`=default, `true`=enabled, `<n>`=workers).  
7. **`ga`**: Genetic algorithm parameters (default integrated).

## Sample Files

Three sample JSON files are provided to help users get started:

1. **Microgrid Example**  
   - File ID: `4b534fa2-0f92-9699-d5e8-94dd380da2de`

2. **District Cooling Example**  
   - File ID: `365ef9bb-4cef-3ef3-1381-80f31eaa124a`

3. **District Heating Example**  
   - File ID: `caab2c2a-de7d-b699-d503-23d8b2113891`
