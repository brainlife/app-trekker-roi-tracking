#!/usr/bin/env python3

import Trekker
import json
import os,sys
sys.path.append('./')
import trekkerIO

def trekker_tracking(rois_to_track,rois,hemispheres,Min_Degree,Max_Degree,exclusion,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init):
	
	# initialize FOD
	FOD = FOD_path[-9:-7].decode()
	if FOD[0] == 'x':
		FOD =  FOD_path[-8:-7].decode()

	mytrekker=Trekker.initialize(FOD_path)

	# begin looping through LGNs to track
	for Rois in range(len(rois_to_track)):
		print("tracking from %s" %rois_to_track[Rois])

		if Rois != 0:
			mytrekker.resetParameters()

		# set seed image
		if os.path.isfile("%s/ROI%s.nii.gz" %(rois,rois_to_track[Rois])):
			seed = "%s/ROI%s.nii.gz" %(rois,rois_to_track[Rois])
		else:
			seed = "%s/%s.nii.gz" %(rois,rois_to_track[Rois])

		seed = seed.encode()

		thalLatPost = "thalLatPost_%s.nii.gz" %(rois_to_track[Rois])
		thalLatPost = thalLatPost.encode()

		for Degrees in range(len(Min_Degree)):

			print("Eccentricity %s to %s" %(str(Min_Degree[Degrees]),str(Max_Degree[Degrees])))
	
			if Degrees != 0:
				mytrekker.resetParameters()

			# begin looping tracking
			for amps in range(len(min_fod_amp)):

				if amps != 0:
					mytrekker.resetParameters()

				for curvs in range(len(curvatures)):
					
					if curvs != 0:
						mytrekker.resetParameters()

					for step in range(len(step_size)):

						if step != 0:
							mytrekker.resetParameters()
						
						if min_fod_amp[amps] != 'default':
							print(min_fod_amp[amps])
							Amps = float(min_fod_amp[amps])
							mytrekker.minFODamp(Amps)

							if probe_length != ['default']:
								mytrekker.probeLength(Amps)

						if curvatures[curvs] != 'default':
							print(curvatures[curvs])
							Curvs = float(curvatures[curvs])	
							mytrekker.minRadiusOfCurvature(Curvs)

						if step_size[step] != 'default':
							print(step_size[step])
							Step = float(step_size[step])
							mytrekker.stepSize(Step)
						
						# set include and exclude definitions
						mytrekker.seed_image(seed)
						#mytrekker.pathway_A_discard_if_enters(csf)
						mytrekker.pathway_A_stop_at_exit(seed)
						mytrekker.pathway_B_require_entry(thalLatPost)
						mytrekker.pathway_B_discard_if_enters(csf)

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

						# set termination ROI
						v1 = "%s.Ecc%sto%s.nii.gz" %(hemispheres[Rois],Min_Degree[Degrees],Max_Degree[Degrees])
						v1 = v1.encode()
						mytrekker.pathway_B_require_entry(v1)
						mytrekker.pathway_B_stop_at_entry(v1)

						# set exclusion if provided
						if exclusion[:] != [""]:
							# set file paths
							if os.path.isfile("%s/ROI%s.nii.gz" %(rois,exclusion[Rois])):
								Exclusion = "%s/ROI%s.nii.gz" %(rois,exclusion[Rois])
							else:
								Exclusion = "%s/%s.nii.gz" %(rois,exclusion[Rois])

							Exclusion = Exclusion.encode()
							mytrekker.pathway_B_discard_if_enters(Exclusion)
						
						mytrekker.printParameters()
						output_name = 'track%s_hemi%s_Ecc%sto%s_lmax%s_FOD%s_curv%s_step%s.vtk' %(str(Rois+1),hemispheres[Rois],str(Min_Degree[Degrees]),str(Max_Degree[Degrees]),str(FOD),str(min_fod_amp[amps]),str(curvatures[curvs]),str(step_size[step]))

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
		exclusion = config['exclusion'].split()
		best_at_init = config["bestAtInit"]
		Min_Degree = config["min_degree"].split()
		Max_Degree = config["max_degree"].split()
		hemispheres = config["hemispheres"].split()

	# paths to preprocessed files
	#csf_path  =  b"csf_bin.nii.gz"

	# begin tracking
	if single_lmax == True:

		# set FOD path
		FOD_path = eval('lmax%s' %str(max_lmax)).encode()
		
		trekker_tracking(roipair,rois,hemispheres,Min_Degree,Max_Degree,exclusion,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)

	else:

		for csd in range(2,max_lmax,2):
			FOD_path = eval('lmax%s' %str(csd+2)).encode()
			
			trekker_tracking(roipair,rois,hemispheres,Min_Degree,Max_Degree,exclusion,FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)


if __name__ == '__main__':
	tracking()
