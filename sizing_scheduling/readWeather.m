function  [solar_irad, T_amb, T_cell, Hours, hours]  = readWeather(weather_data)

solar_irad = weather_data.Beam_Irradiance;
T_amb = weather_data.Ambient_Temperature;
T_cell = weather_data.Cell_Temperature;
Hours = weather_data.Hour;
hours = length(solar_irad);


end