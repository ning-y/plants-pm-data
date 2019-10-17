Description of Data
===================

- **anova-debug-non-identical**: Once we observed that readings in 3 parallel
  boxes do not seem to be consistent with each other, we ran a series of
  'nothing' trials to generate enough data to see if our observations were true.
- **sensor-calibration-poor**: Then, we thought that the difference might be in
  part due to sensors being mis-calibrated. We could manually calibrate the
  sensors by modelling each sensor's readings with relation to a reference
  sensor. These series of trials try to do that, but end up being inappropriate
  for the purpose, since each sensor's readings are too far apart for them to be
  considered to be reading at the same time point.
- **sensor-calibration**: A re-run of the above with sensor readings <= 5s
  apart, using some modifications made to the scribe bot.
