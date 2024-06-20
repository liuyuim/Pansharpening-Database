function [] = Mat2CreatHdf5 (hdf5_file, gt, lms, ms, pan)

    h5create(hdf5_file, '/gt', size(gt), 'Datatype', 'double');
    h5write(hdf5_file, '/gt', gt);
    
    h5create(hdf5_file, '/lms', size(lms), 'Datatype', 'double');
    h5write(hdf5_file, '/lms', lms);
    
    h5create(hdf5_file, '/ms', size(ms), 'Datatype', 'double');
    h5write(hdf5_file, '/ms', ms);
    
    h5create(hdf5_file, '/pan', size(pan), 'Datatype', 'double');
    h5write(hdf5_file, '/pan', pan);
    
    % file = hdf5info('hdf5_file.h5')


end