# Meeting with mathworks sales reps demonstrating tools for data analysis

## Notes
- signalLabeler (app) -> {interactive signal labeling with live plot, saving annotations, predictive repeated labeling by detecting features within one selection and repeating selection in lookeahead to suggest further features, automatic follow up plotting of selection during annotation such as frequency domain plot, }

- signalAnalyzer (app) -> {(shortcuts to spawn frequency, time frequency, filtered, all sorts of transformed views of input data),(Synchronzied view updates across plots as pan and zoom performed),(convert to script: automatically convert all plots generated in GUI to .m script for versioning, manual analysis, reproduction, vcs),(Export to code includes any preprocessing or signal processing steps implemented using the graphical app)}

- signalMultiResolutionAnalyzer (app) -> {(MODWT technique: decompose noisy signal into mutually exclusive freq bands and reconstruct signal only using feature-rich freq bands),(Good for emperical filter design, uses discrete wavelet transform)}

- see if they include wavelet designer

- matlab AI/ML philosophy: Apps are premade to implement different techniques, models. You shouldn't be concerned with implementing AND tuning models until you've explored all of them to make a good chocie of model, then tune. With signals loaded into matlab, select from different ML apps to test each and compare results. 
