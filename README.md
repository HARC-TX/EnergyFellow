# Energy Fellow Software Tool

## Introduction

The **Energy Fellow Software Tool** is an online platform designed to simplify and enhance feasibility analysis for District Energy (DE) systems and multi-building microgrids. Developed by **HARC** in collaboration with **UH** and **Fugro**, and funded by the **DOE**, the tool aims to:
- Reduce costs and engineering barriers.
- Provide advanced assessments using GIS capabilities and downscaled climate models.
- Utilize AI to benchmark solutions and analyze economic outcomes.

By making feasibility studies accessible, the tool promotes the adoption of DE systems, which improve cost efficiency, resilience, and decarbonization.

---

## Usage

### Docker
Run the tool with:
```bash
docker run --rm --network host amo-comp-engine [user_id] [start-up parameters]
```
### MATLAB
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
