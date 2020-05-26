import numpy as np
import vtk

DESCRIPTION = """
    Trekker input output functions
"""

class Tractogram:
    def __init__(self):
        self.count            = 0;
        self.points           = [];
        self.idxEnds          = [];
        self.seedCoordinates  = [];
        self.colors           = [];
        self.FODamp           = [];
        self.tangents         = [];
        self.k1axes           = [];
        self.k2axes           = [];
        self.k1s              = [];
        self.k2s              = [];
        self.curvatures       = [];
        self.likelihoods      = [];
    def info(self):
        print("count:           " + str(self.count));
        print("points:          " + str(np.shape(self.points)));
        print("idxEnds:         " + str(np.shape(self.idxEnds)));
        print("seedCoordinates: " + str(np.shape(self.seedCoordinates)));
        print("colors:          " + str(np.shape(self.colors)));
        print("FODamp:          " + str(np.shape(self.FODamp)));
        print("tangents:        " + str(np.shape(self.tangents)));
        print("k1axes:          " + str(np.shape(self.k1axes)));
        print("k2axes:          " + str(np.shape(self.k2axes)));
        print("k1s:             " + str(np.shape(self.k1s)));
        print("k2s:             " + str(np.shape(self.k2s)));
        print("curvatures:      " + str(np.shape(self.curvatures)));
        print("likelihoods:     " + str(np.shape(self.likelihoods)));


def read(vtk_fname):

    vtkReader = vtk.vtkPolyDataReader();
    vtkReader.ReadAllVectorsOn();
    vtkReader.ReadAllScalarsOn();
    vtkReader.SetFileName(vtk_fname);
    vtkReader.Update();
    
    vtkData = vtkReader.GetOutput();
    
    seedCoordinates = vtkData.GetCellData().GetArray("seedCoordinates");
    colors          = vtkData.GetPointData().GetArray("colors");
    FODamp          = vtkData.GetPointData().GetArray("FODamp");
    tangents        = vtkData.GetPointData().GetArray("tangents");
    k1axes          = vtkData.GetPointData().GetArray("k1axes");
    k2axes          = vtkData.GetPointData().GetArray("k2axes");
    k1s             = vtkData.GetPointData().GetArray("k1s");
    k2s             = vtkData.GetPointData().GetArray("k2s");
    curvatures      = vtkData.GetPointData().GetArray("curvatures");
    likelihoods     = vtkData.GetPointData().GetArray("likelihoods");

    tractogram      = Tractogram();
    
    tractogram.count   = vtkData.GetNumberOfCells();
    tractogram.points  = [];
    tractogram.idxEnds = [];
    
    curIdxEnd = 0;
    for i in range(tractogram.count):
        _points             = vtkData.GetCell(i).GetPoints();
        _points             = np.transpose(np.array([_points.GetPoint(j)      for j in range(_points.GetNumberOfPoints())]).astype('float32'));
        tractogram.points.append(_points.tolist());
        curLength           = np.shape(_points)[1];
        
        if (seedCoordinates is not None):
            tmp = np.transpose(np.array([seedCoordinates.GetValue(j)          for j in range(i*3,(i+1)*3)]).astype('float32'));
            tractogram.seedCoordinates.append(tmp.tolist());
        
        if (colors is not None):
            tmp = np.transpose(np.reshape(np.array([colors.GetValue(j)        for j in range(curIdxEnd*3,(curIdxEnd+curLength)*3)]).astype('float32'),(curLength,3)));
            tractogram.colors.append(tmp.tolist());
            
        if (FODamp is not None):
            tmp = np.transpose(np.reshape(np.array([FODamp.GetValue(j)        for j in range(curIdxEnd,    (curIdxEnd+curLength))]).astype('float32'),(curLength,1)));
            tractogram.FODamp.append(tmp.tolist());
            
        if (tangents is not None):
            tmp = np.transpose(np.reshape(np.array([tangents.GetValue(j)      for j in range(curIdxEnd*3,(curIdxEnd+curLength)*3)]).astype('float32'),(curLength,3)));
            tractogram.tangents.append(tmp.tolist());
            
        if (k1axes is not None):
            tmp = np.transpose(np.reshape(np.array([k1axes.GetValue(j)        for j in range(curIdxEnd*3,(curIdxEnd+curLength)*3)]).astype('float32'),(curLength,3)));
            tractogram.k1axes.append(tmp.tolist());
            
        if (k2axes is not None):
            tmp = np.transpose(np.reshape(np.array([k2axes.GetValue(j)        for j in range(curIdxEnd*3,(curIdxEnd+curLength)*3)]).astype('float32'),(curLength,3)));
            tractogram.k2axes.append(tmp.tolist());
            
        if (k1s is not None):
            tmp = np.transpose(np.reshape(np.array([k1s.GetValue(j)           for j in range(curIdxEnd,    (curIdxEnd+curLength))]).astype('float32'),(curLength,1)));
            tractogram.k1s.append(tmp.tolist());
            
        if (k2s is not None):
            tmp = np.transpose(np.reshape(np.array([k2s.GetValue(j)           for j in range(curIdxEnd,    (curIdxEnd+curLength))]).astype('float32'),(curLength,1)));
            tractogram.k2s.append(tmp.tolist());
            
        if (curvatures is not None):
            tmp = np.transpose(np.reshape(np.array([curvatures.GetValue(j)    for j in range(curIdxEnd,    (curIdxEnd+curLength))]).astype('float32'),(curLength,1)));
            tractogram.curvatures.append(tmp.tolist());

        if (likelihoods is not None):
            tmp = np.transpose(np.reshape(np.array([likelihoods.GetValue(j)   for j in range(curIdxEnd,    (curIdxEnd+curLength))]).astype('float32'),(curLength,1)));
            tractogram.likelihoods.append(tmp.tolist());

        curIdxEnd += np.shape(_points)[1];
        tractogram.idxEnds.append(curIdxEnd);
        
    return tractogram;



def write(tractogram,vtk_fname):
    
    k = 0;
    
    points = vtk.vtkPoints();
    lines  = vtk.vtkCellArray();
    
    seedCoordinates     = vtk.vtkFloatArray();   seedCoordinates.SetNumberOfComponents(3);  seedCoordinates.SetName("seedCoordinates");
    colors              = vtk.vtkFloatArray();   colors.SetNumberOfComponents(3);           colors.SetName("colors");
    FODamp              = vtk.vtkFloatArray();   FODamp.SetNumberOfComponents(1);           FODamp.SetName("FODamp");
    tangents            = vtk.vtkFloatArray();   tangents.SetNumberOfComponents(3);         tangents.SetName("tangents");
    k1axes              = vtk.vtkFloatArray();   k1axes.SetNumberOfComponents(3);           k1axes.SetName("k1axes");
    k2axes              = vtk.vtkFloatArray();   k2axes.SetNumberOfComponents(3);           k2axes.SetName("k2axes");
    k1s                 = vtk.vtkFloatArray();   k1s.SetNumberOfComponents(1);              k1s.SetName("k1s");
    k2s                 = vtk.vtkFloatArray();   k2s.SetNumberOfComponents(1);              k2s.SetName("k2s");
    curvatures          = vtk.vtkFloatArray();   curvatures.SetNumberOfComponents(1);       curvatures.SetName("curvatures");
    likelihoods         = vtk.vtkFloatArray();   likelihoods.SetNumberOfComponents(1);      likelihoods.SetName("likelihoods");    
    
    for i in range(tractogram.count):

        trk = np.transpose(tractogram.points[i]);
        lines.InsertNextCell(trk.shape[0]);
        
        if (tractogram.seedCoordinates  != [] ): seedCoordinates.InsertNextTuple([tractogram.seedCoordinates[i][0],tractogram.seedCoordinates[i][1],tractogram.seedCoordinates[i][2]]);
        
        for j in range(trk.shape[0]):
            points.InsertNextPoint(trk[j,:]);
            lines.InsertCellPoint(k);
            k += 1;
            
            if (tractogram.colors        != [] ):          colors.InsertNextTuple([     tractogram.colors[i][0][j],   tractogram.colors[i][1][j],  tractogram.colors[i][2][j]]);
            if (tractogram.FODamp        != [] ):          FODamp.InsertNextTuple([     tractogram.FODamp[i][0][j]]);
            if (tractogram.tangents      != [] ):        tangents.InsertNextTuple([   tractogram.tangents[i][0][j], tractogram.tangents[i][1][j],tractogram.tangents[i][2][j]]);
            if (tractogram.k1axes        != [] ):          k1axes.InsertNextTuple([     tractogram.k1axes[i][0][j],   tractogram.k1axes[i][1][j],  tractogram.k1axes[i][2][j]]);
            if (tractogram.k2axes        != [] ):          k2axes.InsertNextTuple([     tractogram.k2axes[i][0][j],   tractogram.k2axes[i][1][j],  tractogram.k2axes[i][2][j]]);
            if (tractogram.k1s           != [] ):             k1s.InsertNextTuple([        tractogram.k1s[i][0][j]]);
            if (tractogram.k2s           != [] ):             k2s.InsertNextTuple([        tractogram.k2s[i][0][j]]);
            if (tractogram.curvatures    != [] ):      curvatures.InsertNextTuple([ tractogram.curvatures[i][0][j]]);
            if (tractogram.likelihoods   != [] ):     likelihoods.InsertNextTuple([tractogram.likelihoods[i][0][j]]);
            
            
    
    vtkData = vtk.vtkPolyData();
    vtkData.SetPoints(points);
    vtkData.SetLines(lines);
    
    if (tractogram.seedCoordinates  != [] ): vtkData.GetCellData().SetScalars(seedCoordinates);
    if (tractogram.colors           != [] ): vtkData.GetPointData().SetScalars(colors);
    if (tractogram.FODamp           != [] ): vtkData.GetPointData().AddArray(FODamp);
    if (tractogram.tangents         != [] ): vtkData.GetPointData().AddArray(tangents);
    if (tractogram.k1axes           != [] ): vtkData.GetPointData().AddArray(k1axes);
    if (tractogram.k2axes           != [] ): vtkData.GetPointData().AddArray(k2axes);
    if (tractogram.k1s              != [] ): vtkData.GetPointData().AddArray(k1s);
    if (tractogram.k2s              != [] ): vtkData.GetPointData().AddArray(k2s);
    if (tractogram.curvatures       != [] ): vtkData.GetPointData().AddArray(curvatures);
    if (tractogram.likelihoods      != [] ): vtkData.GetPointData().AddArray(likelihoods);
    
    w = vtk.vtkPolyDataWriter();
    w.SetFileTypeToBinary();
    w.SetInputData(vtkData);
    w.SetFileName(vtk_fname);
    w.Write();    