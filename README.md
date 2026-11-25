<h1 align="center">Trekker ROI Tracking</h1>

<p align="center">
  Streamlines between regions of interest, including the optic radiation and optic tract, tracked with Trekker parallel transport tractography on CSD FODs.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.355"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.355-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Tracks streamlines between user-specified pairs of ROIs with Trekker parallel transport tractography on CSD FODs, with optional exclusion ROIs and ensemble settings, and outputs a tractogram and a white matter classification.**

For each ROI pair listed in roiPair, seeds Trekker in the first ROI and keeps streamlines that exit it and enter the second ROI, discarding any that enter CSF or the pair's exclusion ROI (from which the seed and target are subtracted with FSL). Several FOD amplitudes, curvatures and step sizes can be listed to ensemble track, and tracking can span several lmax values. Use it to reconstruct specific pathways between known regions; it needs DWI, CSD FODs, ROIs and a 5-tissue-type mask of the same subject. ROIs must match the DWI grid unless reslice is true.

| | |
|---|---|
| **Inputs** | `neuro/dwi` · `neuro/csd` · `neuro/rois` · `neuro/mask` · `neuro/mask` (optional) |
| **Outputs** | `neuro/track/tck` · `neuro/mask` · `neuro/wmc` · `raw` |
| **Container** | `brainlife/freesurfer-mini:6.0.1` |
| **Resources** | 8 CPUs · 30 GB memory · 30 h walltime |
| **Requires** | `FREESURFER_LICENSE` |
| **Run it** | [doi.org/10.25663/brainlife.app.355](https://doi.org/10.25663/brainlife.app.355) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `dwi` | `neuro/dwi` | yes | Preprocessed diffusion-weighted image with bvecs and bvals. |
| `csd` | `neuro/csd` | yes | Constrained spherical deconvolution FODs (lmax2 to lmax14 files); the FOD at the chosen lmax is what Trekker tracks on. Must contain the FOD file for the requested lmax (or every lmax when single_lmax is false). |
| `rois` | `neuro/rois` | yes | Directory of ROI NIfTI files (ROI<name>.nii.gz or <name>.nii.gz) referenced by name in the parameters. ROIs must be in the same space and dimensions as the DWI; otherwise set reslice to true (assumes correct alignment). |
| `mask` | `neuro/mask` (5tt_masks) | yes | 5-tissue-type segmentation in DWI space; its CSF is binarised (threshold 0.3) to discard streamlines. |
| `brainmask` | `neuro/mask` | no | Optional whole-brain mask; if absent a mask is computed from the DWI with MRtrix3 dwi2mask. |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `track` | `neuro/track/tck` | Tractogram (.tck) of all streamlines generated, merged across ROI pairs and ensemble settings. |
| `brainmask` | `neuro/mask` | Brain mask in DWI space used during tracking (the input mask or one computed with dwi2mask). |
| `wmc` | `neuro/wmc` | White matter classification (classification.mat) assigning streamlines to each tracked pathway, with surface meshes of the ROIs for the brainlife viewer. |
| `raw` | `raw` | Per-run tractograms and tckinfo text files kept as derivatives. |

<details>
<summary><b>Parameters</b> (18)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `min_length` | number | `10` | Minimum streamline length. (mm) |
| `max_length` | number | `200` | Maximum streamline length. (mm) |
| `lmax` | number | `8` | Spherical harmonic order of the FOD to track on (the maximum order when ensembling across lmax). |
| `roiPair` | string |  | this field is to designate the ROI names to track between. Multiple tracks can be done at the same time but entering the pairs on a new line. for example, for a single track with ROI names of parc-10 and parc-193, this input would be: parc-10 parc-193 if you wanted to do a second track between ROIs with names of parc-25 and parc-250, this input would be: parc-10 parc-193 parc-25 parc-250 Please see ROI datatype for exact name of each. |
| `exclusion` | string |  | this field is the exact ROI name or number from the ROI datatype for the exclusion ROIS. Just like in the roiPair field, you can enter a different exclusion ROI for each tract by adding a new line. NOTE: can only do one exclusion ROI per tract. If you do not want to use exclusion ROIs, leave blank |
| `count` | number | `500` | Number of streamlines (Trekker seed count) to generate per ROI pair and setting. |
| `curvatures` | string | `default` | minimum radius of curvature. If left as 'default', trekker will automatically determine best curvature. Otherwise, enter value of radius of curvature (i.e 0.5) |
| `stepsize` | string | `default` | step size. If left as 'default', trekker will automatically determine best step size. Otherwise, enter value of step size (i.e 0.5) |
| `single_lmax` | boolean | `true` | If true, track only on the FOD of the selected lmax; if false, run ensemble tracking across even lmax values up to lmax. |
| `minfodamp` | string | `default` | minimum FOD amplitude. If left as 'default', trekker will automatically determine best FOD amplitude. Otherwise, enter value of FOD amplitude (i.e 0.5) |
| `maxsampling` | string | `default` | Maximum sampling per seed for Trekker; 'default' lets Trekker choose. |
| `maxtrials` | string | `default` | Maximum seed trials for Trekker; 'default' lets Trekker choose. |
| `probecount` | string | `default` | Trekker probe count; 'default' lets Trekker choose. |
| `probelength` | string | `default` | Trekker probe length; 'default' lets Trekker choose. |
| `proberadius` | string | `default` | Trekker probe radius; 'default' lets Trekker choose. |
| `probequality` | string | `default` | Trekker probe quality; 'default' lets Trekker choose. |
| `bestAtInit` | boolean | `false` | Passed to Trekker useBestAtInit: start each streamline from the best initial direction. |
| `reslice` | boolean | `false` | If true, reslice the ROIs to the DWI grid with FreeSurfer mri_vol2vol (header-based) before tracking; set when ROIs do not match DWI dimensions. |

</details>

<!-- brainlife-app:end -->

## How it works

[Trekker](https://dmritrekker.github.io) implements parallel transport tractography (PTT), a fibre tracking algorithm based on parallel transport frames (Aydogan and Shi, 2019). This repository wraps Baran Aydogan's Trekker so that it can be run on brainlife.io; all credit for the tracking algorithm belongs to him.

The tracking Apps run Trekker on the constrained spherical deconvolution (CSD) FODs of a subject:

1. The ROIs are brought onto the DWI grid (set `reslice` if they do not match it), and a brain mask (computed with MRtrix3 `dwi2mask` if you do not give one) and a binary CSF mask from the 5-tissue-type mask are prepared.
2. For each pathway, Trekker seeds in the first ROI and keeps the streamlines that reach the second, discarding any that enter the CSF or an exclusion ROI (from which the seed and target are subtracted with FSL).
3. Several FOD amplitudes (`minfodamp`), curvatures (`curvatures`) and step sizes (`stepsize`) can be listed to ensemble track; with `single_lmax` off, tracking also runs over every even lmax up to `lmax`. Left at `default`, Trekker chooses these values itself.
4. The streamlines are merged into one `.tck` and a white matter classification (compiled MATLAB), with surface meshes of the ROIs for the brainlife.io viewer.

## Versions on brainlife.io

Each App is built from its own branch of this repository.

| App | Branch | Run it | Status |
|---|---|---|---|
| Generate surface visualizations of ROIs for WMC Datatype Viewer | [`tmp-add-rois`](https://github.com/brainlife/app-trekker-roi-tracking/tree/tmp-add-rois) | [doi:10.25663/brainlife.app.550](https://doi.org/10.25663/brainlife.app.550) | current |
| Trekker ROI Tracking (DWI) | [`master-app-v1.2`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-v1.2) | [doi:10.25663/brainlife.app.355](https://doi.org/10.25663/brainlife.app.355) | current |
| Trekker ROI Tracking (DWI) based on Eccentricity | [`master-app-eccentricity-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-eccentricity-v1.0) | [doi:10.25663/brainlife.app.415](https://doi.org/10.25663/brainlife.app.415) | current |
| Tracking the Visual White Matter (TVWM) (Trekker) - Eccentricity | [`master-app-eccentricity-visualroi-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-eccentricity-visualroi-v1.0) | [doi:10.25663/brainlife.app.418](https://doi.org/10.25663/brainlife.app.418) | current |
| Track the Human Optic RAdiation (THORA) - Trekker | [`optic-radiation-v1.2`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-radiation-v1.2) | [doi:10.25663/brainlife.app.226](https://doi.org/10.25663/brainlife.app.226) | current |
| Track the Human Optic TRAct (THOTRA) - Trekker | [`optic-tract-true-v1.2`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-tract-true-v1.2) | [doi:10.25663/brainlife.app.357](https://doi.org/10.25663/brainlife.app.357) | current |
| Track the Human Optic RAdiation (THORA) - Trekker (V2) | [`optic-radiation-v2-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-radiation-v2-v1.0) | [doi:10.25663/brainlife.app.404](https://doi.org/10.25663/brainlife.app.404) | deprecated |
| Track the Human Optic TRAct (THOTRA) - Trekker (dtiinit) | [`optic-tract-v1.1`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-tract-v1.1) | [doi:10.25663/brainlife.app.360](https://doi.org/10.25663/brainlife.app.360) | deprecated |
| Trekker ROI Tracking (dtiinit) | [`master-app-v1.1`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-v1.1) | [doi:10.25663/brainlife.app.358](https://doi.org/10.25663/brainlife.app.358) | deprecated |
| Track the Human Optic RAdiation (THORA) - Trekker - V1.0 | [`optic-radiation-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-radiation-v1.0) | [doi:10.25663/brainlife.app.354](https://doi.org/10.25663/brainlife.app.354) | deprecated |
| Track the Human Optic TRAct (THOTRA) - Trekker - v1.0 | [`optic-tract-true-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-tract-true-v1.0) | [doi:10.25663/brainlife.app.353](https://doi.org/10.25663/brainlife.app.353) | deprecated |
| Track the Human Optic RAdiation (THORA) - Trekker (dtiinit) -v1.0 | [`optic-tract-true-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/optic-tract-true-v1.0) | [doi:10.25663/brainlife.app.351](https://doi.org/10.25663/brainlife.app.351) | deprecated |
| Trekker ROI Tracking (dtiinit) - v1.0 | [`master-app-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-v1.0) | [doi:10.25663/brainlife.app.338](https://doi.org/10.25663/brainlife.app.338) | deprecated |
| Trekker ROI Tracking (dwi) - v1.0 | [`master-app-v1.0`](https://github.com/brainlife/app-trekker-roi-tracking/tree/master-app-v1.0) | [doi:10.25663/brainlife.app.280](https://doi.org/10.25663/brainlife.app.280) | deprecated |

What the current Apps do:

- **Trekker ROI Tracking (DWI)**: tracks between the ROI pairs listed in `roiPair` (one pair per line), each with optional exclusion ROIs in `exclusion`.
- **Based on Eccentricity**: tracks between pairs of eccentricity-binned ROIs, for each eccentricity bin.
- **TVWM - Eccentricity**: seeds in the white matter and terminates in eccentricity-binned visual ROIs, to track the visual white matter.
- **THORA**: tracks the optic radiation from the LGN (`lgn`) to V1 (`v1`) in each hemisphere, through a lateral-posterior thalamic plane generated with wma_tools and avoiding the medial-posterior thalamus, the CSF and any `exclusion` ROIs (for example opposite-hemisphere or cerebellar white matter, or the hippocampus).
- **THOTRA**: tracks the optic tract from the optic chiasm to the LGN.
- **Generate surface visualizations of ROIs** (`tmp-add-rois`): a utility that converts each ROI volume into a VTK surface mesh and adds it to an existing white matter classification, so the ROIs are shown in the brainlife.io WMC viewer. It does no tracking.

## Running the App

### On brainlife.io

Open the App that matches your question from the table above. The tracking Apps take a preprocessed `neuro/dwi` dataset, its CSD FODs (`neuro/csd`, `lmax2` to `lmax14`), a `neuro/rois` dataset and a 5-tissue-type mask (`neuro/mask`, tag `5tt_masks`) of the same subject, plus an optional brain mask. ROIs are referred to by name: `lh.lgn` for `rois/ROIlh.lgn.nii.gz` or `rois/lh.lgn.nii.gz` (leave out the `ROI` prefix). Press **Execute**: the App writes a tractogram (`neuro/track/tck`), a classification (`neuro/wmc`), the brain mask it used (`neuro/mask`) and, for most Apps, a `raw` dataset with intermediate files.

The ROI visualisation App ([doi:10.25663/brainlife.app.550](https://doi.org/10.25663/brainlife.app.550)) takes a `neuro/wmc` and a `neuro/rois` dataset and writes the classification back with the ROI surfaces added (tag `surface_rois`).

### Locally

You need [Singularity/Apptainer](https://apptainer.org/), [`jq`](https://jqlang.github.io/jq/) and, for the ROI and eccentricity tracking Apps, a [FreeSurfer license](https://surfer.nmr.mgh.harvard.edu/registration.html). `main` runs the steps in the `brainlife/trekker:0.6.1`, `brainlife/mrtrix3:3.0.0`, `brainlife/fsl:5.0.11`, `brainlife/freesurfer-mini:6.0.1`, `brainlife/mcr:neurodebian1604-r2017a` and `brainlife/pythonvtk:1.1` containers, so MATLAB is not needed.

1. Clone this repository and check out the branch of the App you want, for example `git checkout master-app-v1.2`.
2. Create `config.json` with the paths to your inputs and the tracking options. For Trekker ROI Tracking (DWI):

   ```json
   {
       "dwi": "/input/dwi/dwi.nii.gz",
       "bvals": "/input/dwi/dwi.bvals",
       "bvecs": "/input/dwi/dwi.bvecs",
       "rois": "/input/rois/rois",
       "mask": "/input/5tt/mask.nii.gz",
       "lmax2": "/input/csd/lmax2.nii.gz",
       "lmax4": "/input/csd/lmax4.nii.gz",
       "lmax6": "/input/csd/lmax6.nii.gz",
       "lmax8": "/input/csd/lmax8.nii.gz",
       "lmax10": "/input/csd/lmax10.nii.gz",
       "lmax12": "/input/csd/lmax12.nii.gz",
       "lmax14": "/input/csd/lmax14.nii.gz",
       "roiPair": "lh.lgn lh.v1",
       "exclusion": "",
       "lmax": 8,
       "single_lmax": true,
       "count": 500,
       "min_length": 10,
       "max_length": 200,
       "minfodamp": "default",
       "curvatures": "default",
       "stepsize": "default",
       "reslice": false
   }
   ```

   The THORA Apps take `lgn`, `v1` and `exclusion` (space-separated ROI names, one per hemisphere) instead of `roiPair`.

3. Export your FreeSurfer license and run the App:

   ```bash
   export FREESURFER_LICENSE="$(cat ~/freesurfer/license.txt)"
   ./main
   ```

## Outputs

```text
track/
└── track.tck              all streamlines, merged across pathways and ensemble settings
wmc/
├── classification.mat     streamline-to-pathway assignment
├── tracts/
└── surfaces/              surface meshes of the ROIs for the brainlife.io viewer
raw/                       per-pathway tractograms and track lists
```

## Troubleshooting

- **`tracking failed`**: no `classification.mat` was produced, usually because no streamlines were found. Check the ROI names, the exclusion ROIs and the tracking parameters, and look at the log.
- **`Please set FREESURFER_LICENSE in .bashrc`**: export your FreeSurfer license as `FREESURFER_LICENSE`.
- **`something failed.`** (ROI visualisation App): no ROI surfaces were written. Check the `rois` input.

## Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- Aydogan DB, Shi Y. A novel fiber tracking algorithm using parallel transport frames. *Proceedings of the 27th Annual Meeting of the ISMRM*, Montreal (2019).
- Trekker ROI Tracking (DWI). brainlife.io App. [doi:10.25663/brainlife.app.355](https://doi.org/10.25663/brainlife.app.355)
- Aydogan D.B., Shi Y. A novel fiber tracking algorithm using parallel transport frames. Proceedings of the 27th Annual Meeting of ISMRM (2019).
- Fischl. FreeSurfer. *NeuroImage* 62:774-781 (2012). [doi:10.1016/j.neuroimage.2012.01.021](https://doi.org/10.1016/j.neuroimage.2012.01.021)
- Jenkinson et al. FSL. *NeuroImage* 62:782-790 (2012). [doi:10.1016/j.neuroimage.2011.09.015](https://doi.org/10.1016/j.neuroimage.2011.09.015)
- Tournier et al. MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. *NeuroImage* 202:116137 (2019). [doi:10.1016/j.neuroimage.2019.116137](https://doi.org/10.1016/j.neuroimage.2019.116137)
- Aydogan and Shi. Parallel Transport Tractography. *IEEE Transactions on Medical Imaging* 40:635-647 (2021). [doi:10.1109/TMI.2020.3034038](https://doi.org/10.1109/TMI.2020.3034038)
- Bullock et al. Associative white matter connecting the dorsal and ventral posterior human cortex. *Brain Structure and Function* 224:2631-2660 (2019). [doi:10.1007/s00429-019-01907-8](https://doi.org/10.1007/s00429-019-01907-8)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

- Baran Aydogan (author of Trekker)
- Brad Caron

**Contributors:** Soichi Hayashi, Franco Pestilli

## Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

## License

[MIT](LICENSE). Trekker is distributed under its own [license](https://dmritrekker.github.io).
