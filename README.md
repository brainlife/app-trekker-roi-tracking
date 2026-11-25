# app-trekker-roi-tracking

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

**Utility that converts each ROI volume into a VTK surface mesh and adds it to a white matter classification so the ROIs display in the brainlife WMC viewer.**

Copies the input classification and tract files, converts every NIfTI ROI in the rois input into a surface mesh with VTK and writes the meshes and an index.json into the wmc surfaces directory. Use it after an ROI tracking App to visualise the ROIs alongside the tracts. Visualisation only; it does not change the classification.

Run it on brainlife.io: [https://doi.org/10.25663/brainlife.app.550](https://doi.org/10.25663/brainlife.app.550)

| Input | Datatype | Required | Description |
|---|---|---|---|
| `wmc` | `neuro/wmc` | yes | White matter classification (classification.mat, tract JSONs and any existing surfaces) to add ROI surfaces to. |
| `rois` | `neuro/rois` | yes | Directory of ROI NIfTI volumes to convert into surface meshes. |

| Output | Datatype | Description |
|---|---|---|
| `wmc` | `neuro/wmc` | The input classification with ROI surface meshes and surfaces/index.json added. |

Runtime: container `brainlife/pythonvtk:1.1`; 4 CPUs; 16 GB memory; 8 h walltime.

<!-- brainlife-app:end -->

Trekker implements a state-of-the-art tractography algorithm, parallel transport tractography (PTT). This repo wraps Baran Ayodogan's Trekker github repo so that it can be executed on brainlife.io. All credits for this App belongs to Baran Ayodogan <baran.aydogan@aalto.fi>

# How does it work?

TODO - explain how this App works and how it's different from other tractograph algorithm. 

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
	"minfodamp":	0.01,
	"minradius":	0.25,
	"probelength":	0.25,
	"stepsize":	0.25,
	"count":	500,
	"seed_roi":	"8109",
	"term_roi":	"2"
}
```

4) run `./main`

# Citation

[Aydogan2019a]	Aydogan DB, Shi Y., “Parallel transport tractography”, in preparation
[Aydogan2019b]	Aydogan DB, Shi Y., “A novel fiber tracking algorithm using parallel transport frames”, ISMRM 2019, Montreal

