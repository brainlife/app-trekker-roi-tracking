[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.226-blue.svg)](https://doi.org/10.25663/brainlife.app.226)

# Track the Human Optic RAdiation (THORA).

Trekker implements a state-of-the-art tractography algorithm, parallel transport tractography (PTT). This stand-alone app will generate the human optic radiation. This repo wraps Baran Ayodogan's Trekker github repo so that it can be executed on brainlife.io. 

### Authors
- [Baran Ayodogan](baran.aydogan@aalto.fi)
- [Bradley Caron](bacaron@iu.edu)
- [Soichi Hayashi](hayashis@iu.edu)

![ot_or](https://github.com/brainlife/app-trekker-roi-tracking/blob/optic_radiation/opticPathway.jpg)

# How does it work?

This [brainlife.io](brainlife.io/apps) App Tracks the Human Optic RAdiation (THORA) using [Trekker](https://dmritrekker.github.io). 

To run THORA you need to first run the following Apps: 

  (1) [FreeSurfer OSG](https://doi.org/10.25663/bl.app.49) alternatively [FreeSurfer](https://doi.org/10.25663/bl.app.0) 

  (2) [Segment thalamic nuclei](https://doi.org/10.25663/brainlife.app.222) 
  
  (3) [MaTT](https://doi.org/10.25663/bl.app.23) Select the hcp-mmp-b Atlas 
  
  (4) [Diffusion-MRI preprocessing](https://doi.org/10.25663/bl.app.68) 
 
  (5) [Extract the nuclei of the Thalamus](https://doi.org/10.25663/brainlife.app.223) 
  
The following Regions of Interest (ROIs) are needed and obtained from the hcp-mmp-b atlas (step 3 above) and the thalamic nuclei segmentation (step 5 above): - For Left OR: ROI 8109 (thalamic) and ROI 2 (hcp-mmp-b). - For Right OR: ROI 8209 (thalamic) and ROI 183 (hcp-mmp-b).

# Please cite the following work.

[Aydogan2019a]	Aydogan DB, Shi Y., “Parallel transport tractography”, In preparation.

[Aydogan2019b]	Aydogan DB, Shi Y., “A novel fiber tracking algorithm using parallel transport frames”, ISMRM 2019, Montreal.

[Avesani et al. (2019) The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Scientific Data](https://doi.org/10.1038/s41597-019-0073-y)

### Funding 
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.226](https://doi.org/10.25663/brainlife.app.226) via the "Execute" tab.

# Run this App

You can run this App on brainlife.io, or if you'd like to run it locally, you ca do the following.

1) git clone this repo on your machine

2) Stage input file (dwi)

```
bl dataset download <dataset id for any neuro/dwi data and neuro/anat/t1w and neuro/csd and neuro/rois data from barinlife>
```

3) Create config.json (you can copy from config.json.sample)

```
{
	"dwi":	"/tesdata/dwi/dwi.nii.gz",
	"bvals":	"/tesdata/dwi/dwi.bvals",
	"bvecs":	"/tesdata/dwi/dwi.bvecs",
	"t1":	"/tesdata/anat/t1.nii.gz",
	"rois":	"/testdata/rois/rois/",
	"lmax2":	"/tesdata/input_csd/lmax2.nii.gz",
	"lmax4":	"/tesdata/input_csd/lmax4.nii.gz",
	"lmax6":	"/tesdata/input_csd/lmax6.nii.gz",
	"lmax8":	"/tesdata/input_csd/lmax8.nii.gz",
	"lmax10":	"/tesdata/input_csd/lmax10.nii.gz",
	"lmax12":	"/tesdata/input_csd/lmax12.nii.gz",
	"lmax14":	'/testdata/input_csd/lmax14.nii.gz",
	"min_length":	10,
	"max_length":	200,
	"lmax":	8,
	"count":	500,
	"seed_roi":	"8109",
	"term_roi":	"2"
}
```

4) run `./main`
