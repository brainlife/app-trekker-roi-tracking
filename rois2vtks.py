#!/usr/bin/env python

import vtk
import sys
import os
import json
import pandas as pd
import numpy as np

if not os.path.exists("wmc/surfaces"):
   os.makedirs("wmc/surfaces")

with open('config.json','r') as config_f:
    config = json.load(config_f)

if config['reslice'] == 'true':
	rois = './reslice_rois/'
else
	rois = config['rois']
roiNames = os.listdir(rois)

labels = {}
index=[]

for rs in range(len(roiNames)):

    labels[rs] = {}
    label = labels[rs]
    label["label"] = str(rs)
    label["name"] = roiNames[rs].replace('.nii.gz','')
    label["color"] = {}
    label["color"]["r"] = np.random.randint(255)
    label["color"]["g"] = np.random.randint(255)
    label["color"]["b"] = np.random.randint(255)

    img_path = os.path.join(rois,roiNames[rs])

    # import the binary nifti image
    print("loading %s" % img_path)
    reader = vtk.vtkNIFTIImageReader()
    reader.SetFileName(img_path)
    reader.Update()

    print("list unique values (super slow!)")
    out = reader.GetOutput()
    vtk_data=out.GetPointData().GetScalars()
    unique = set()
    for i in range(0, vtk_data.GetSize()):
        v = vtk_data.GetValue(i)
        unique.add(v)


    label_id=int(rs)

    surf_name=label['label']+'.'+label['name']+'.vtk'
    label["filename"] = surf_name
    print(surf_name)

    #label["label"] = label_id
    index.append(label)

    # do marching cubes to create a surface
    surface = vtk.vtkDiscreteMarchingCubes()
    surface.SetInputConnection(reader.GetOutputPort())

    # GenerateValues(number of surfaces, label range start, label range end)
    surface.GenerateValues(1, 1, 1)
    surface.Update()
    #print(surface)

    smoother = vtk.vtkWindowedSincPolyDataFilter()
    smoother.SetInputConnection(surface.GetOutputPort())
    smoother.SetNumberOfIterations(10)
    smoother.NonManifoldSmoothingOn()
    smoother.NormalizeCoordinatesOn()
    smoother.Update()

    connectivityFilter = vtk.vtkPolyDataConnectivityFilter()
    connectivityFilter.SetInputConnection(smoother.GetOutputPort())
    connectivityFilter.SetExtractionModeToLargestRegion()
    connectivityFilter.Update()

    untransform = vtk.vtkTransform()
    untransform.SetMatrix(reader.GetQFormMatrix())
    untransformFilter=vtk.vtkTransformPolyDataFilter()
    untransformFilter.SetTransform(untransform)
    untransformFilter.SetInputConnection(connectivityFilter.GetOutputPort())
    untransformFilter.Update()

    cleaned = vtk.vtkCleanPolyData()
    cleaned.SetInputConnection(untransformFilter.GetOutputPort())
    cleaned.Update()

    deci = vtk.vtkDecimatePro()
    deci.SetInputConnection(cleaned.GetOutputPort())
    deci.SetTargetReduction(0.5)
    deci.PreserveTopologyOn()

    writer = vtk.vtkPolyDataWriter()
    writer.SetInputConnection(deci.GetOutputPort())
    writer.SetFileName("wmc/surfaces/"+surf_name)
    writer.Write()

print("writing surfaces/index.json")
with open("wmc/surfaces/index.json", "w") as outfile:
    json.dump(index, outfile)

print("all done")
