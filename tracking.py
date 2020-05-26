#!/usr/bin/env python3

import Trekker
import json
import os,sys
sys.path.append('./')
import trekkerIO

def trekker_tracking(rois_to_track,rois,oc,csf,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init):
	
	# initialize FOD
	FOD = FOD_path[-9:-7].decode()
	if FOD[0] == 'x':
		FOD =  FOD_path[-8:-7].decode()

	mytrekker=Trekker.initialize(FOD_path)

	# begin looping through LGNs to track
	for Rois in range(len(rois_to_track)):
		print("tracking from optic chiasm")

		if Rois != 0:
			mytrekker.resetParameters()

		# set seed image
		seed = oc

		# set lgn image
		if os.path.isfile("%s/ROI%s.nii.gz" %(rois,rois_to_track[Rois])):
			roi1 = "%s/ROI%s.nii.gz" %(rois,rois_to_track[Rois])
		else:
			roi1 = "%s/%s.nii.gz" %(rois,rois_to_track[Rois])
		
		roi1 = roi1.encode()
		mytrekker.seed_image(seed)

		# set include and exclude definitions
		mytrekker.pathway_A_discard_if_enters(csf)
		mytrekker.pathway_A_stop_at_exit(seed)
		mytrekker.pathway_B_discard_if_enters(csf)
		mytrekker.pathway_B_require_entry(roi1)

		# set non loopable parameters
		# required parameters
		mytrekker.minLength(min_length)
		mytrekker.maxLength(max_length)
		mytrekker.useBestAtInit(best_at_init)
		mytrekker.seed_count(count)

		# if = default, let trekker pick
		if probe_radius != 'default':
			probe_radius = float(probe_radius)
			mytrekker.probeRadius(probe_radius)
		if probe_quality != 'default':
			probe_quality = float(probe_quality)
			mytrekker.probeQuality(probe_quality)
		if probe_length != 'default':
			probe_length = float(probe_length)
			mytrekker.probeLength(probe_length)
		if probe_count != 'default':
			probe_count = float(probe_count)
			mytrekker.probeCount(probe_count)
		if seed_max_trials != 'default':
			seed_max_trials = float(max_sampling)
			mytrekker.seed_maxTrials(seed_max_trials)
		if max_sampling != 'default':
			max_sampling = float(max_sampling)
			mytrekker.maxSamplingPerStep(max_sampling)

		# resource-specific parameter
		mytrekker.numberOfThreads(8)

		# begin looping tracking
		for amps in min_fod_amp:
			if min_fod_amp != ['default']:
				print(amps)
				amps = float(amps)
				mytrekker.minFODamp(amps)

				if probe_length == 'default':
					mytrekker.probeLength(amps)

			else:
				amps = 'default'

			for curvs in curvatures:
				if curvatures != ['default']:
					print(curvs)
					curvs = float(curvs)
					mytrekker.minRadiusOfCurvature(curvs)
				else:
					curvs = 'default'

				for step in step_size:
					if step_size != ['default']:
						print(step)
						step = float(step)
						mytrekker.stepSize(step)
					else:
						step = 'default'
					
					mytrekker.printParameters()
					output_name = 'track%s_lmax%s_FOD%s_curv%s_step%s.vtk' %(str(Rois+1),str(FOD),str(amps),str(curvs),str(step))

					# run the tracking
					Streamlines = mytrekker.run()

					# print output
					tractogram = trekkerIO.Tractogram()
					tractogram.count = len(Streamlines)
					print(tractogram.count)
					tractogram.points = Streamlines
					trekkerIO.write(tractogram,output_name)

	del mytrekker

def tracking():
	# load and parse configurable inputs
	with open('config.json') as config_f:
		config = json.load(config_f)
		max_lmax = config["lmax"]
		rois = config["rois"]
		count = config["count"]
		roipair = config["roiPair"].split()
		min_fod_amp = config["minfodamp"].split()
		curvatures = config["curvatures"].split()
		seed_max_trials = config["maxtrials"]
		max_sampling = config["maxsampling"]
		lmax2 = config["lmax2"]
		lmax4 = config["lmax4"]
		lmax6 = config["lmax6"]
		lmax8 = config["lmax8"]
		lmax10 = config["lmax10"]
		lmax12 = config["lmax12"]
		lmax14 = config["lmax14"]
		single_lmax = config["single_lmax"]
		step_size = config["stepsize"].split()
		min_length = config["min_length"]
		max_length = config["max_length"]
		probe_length = config["probelength"]
		probe_quality = config["probequality"]
		probe_count = config["probecount"]
		probe_radius = config["proberadius"]
		oc = config["oc"]
		best_at_init = config["bestAtInit"]

	# paths to preprocessed files
	csf_path  =  b"csf_bin.nii.gz"

	# full paths to v1
	if os.path.isfile("%s/ROI%s.nii.gz" %(rois,oc)):
		oc = "%s/ROI%s.nii.gz" %(rois,oc)
	else:
		oc = "%s/%s.nii.gz" %(rois,oc)

	oc = oc.encode()

	# begin tracking
	if single_lmax == True:

		# set FOD path
		FOD_path = eval('lmax%s' %str(max_lmax)).encode()
		
		trekker_tracking(roipair,rois,oc,csf_path,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)

	else:

		for csd in range(2,max_lmax,2):
			FOD_path = eval('lmax%s' %str(csd+2)).encode()
			
			trekker_tracking(roipair,rois,oc,csf_path,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)


if __name__ == '__main__':
	tracking()
