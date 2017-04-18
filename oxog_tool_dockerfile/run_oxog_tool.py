import subprocess
import os
import sys
import tarfile
import shutil

def run(cmd):
    print(cmd)
    subprocess.check_call(cmd,shell=True)

run('ln -sTf `pwd` /opt/execution')
run('ln -sTf `pwd`/../inputs /opt/inputs')
run('/cga/fh/pcawg_pipeline/utils/monitor_start.py')

# start task-specific calls
##########################

#copy wdl args to python vars
inputDir = sys.argv[1]

pairID =sys.argv[2] #'${pairID}'
bam_tumor = inputDir + '/' + sys.argv[3] #'${bam_tumor}'
bam_tumor_index = inputDir + '/' + sys.argv[4] #'${bam_tumor_index}'
oxoq = sys.argv[5] #'${oxoq}'
input_vcf_gz = inputDir + '/' + sys.argv[6] #'${input_vcf_gz}'
input_vcf_gz_tbi = inputDir + '/' + sys.argv[7] #'${input_vcf_gz_tbi}'

refdata1=sys.argv[8] #'${refdata1}'


#define the pipeline
PIPELINE='/cga/fh/pcawg_pipeline/pipelines/oxog_pipeline.py'

#define the directory for the pipette server to allow the pipette pipelines to run
PIPETTE_SERVER_DIR='/cga/fh/pcawg_pipeline/utils/pipette_server'

#define the location of the directory for communication data
cwd = os.getcwd()
COMMDIR=os.path.join(cwd,'pipette_status')
OUTDIR=os.path.join(cwd,'pipette_jobs')
REFDIR = os.path.join(cwd,'refdata')
INPUTS=os.path.join(cwd,'inputs')
OUTFILES = os.path.join(cwd,'output_files')

if os.path.exists(COMMDIR):
    shutil.rmtree(COMMDIR)
os.mkdir(COMMDIR)

if not os.path.exists(INPUTS):
    os.mkdir(INPUTS)
if not os.path.exists(OUTFILES):
    os.mkdir(OUTFILES)

# if not os.path.exists(REFDIR):
#     os.symlink(refdata1,REFDIR)
    # os.mkdir(REFDIR)
    # # unpack reference files
    # run('tar xvf %s -C %s'%(refdata1,REFDIR))

#colocate the indexes with the bams via symlinks
# TUMOR_BAM = os.path.join(INPUTS,'tumor.bam')
# TUMOR_INDEX = os.path.join(INPUTS,'tumor.bam.bai')

# if not os.path.exists(TUMOR_BAM):
#     os.rename(bam_tumor,TUMOR_BAM)
#     os.rename(bam_tumor_index,TUMOR_INDEX)

# INPUT_VCF_GZ = os.path.join(INPUTS,'input.vcf.gz')
# INPUT_VCF_GZ_TBI = os.path.join(INPUTS,'input.vcf.gz.tbi')
# if not os.path.exists(INPUT_VCF_GZ):
#     os.link(input_vcf_gz,INPUT_VCF_GZ)
#     os.link(input_vcf_gz_tbi,INPUT_VCF_GZ_TBI)



#run the pipette synchronous runner to process the test data
cmd_str = 'python3 %s/pipetteSynchronousRunner.py '%PIPETTE_SERVER_DIR + ' '.join([COMMDIR,OUTDIR,PIPELINE,COMMDIR,OUTDIR,pairID,bam_tumor,oxoq,input_vcf_gz,'--ref',refdata1])

pipeline_return_code = subprocess.call(cmd_str,shell=True)

# capture module usage
mufn = 'pipette.module.usage.txt'
mus = []
for root, dirs, files in os.walk(OUTDIR):
    if mufn in files:
        fid = open(os.path.join(root,mufn))
        usageheader = fid.readline()
        usage = fid.readline()
        mus.append(usage)
mus.sort()
# output usage for failures to stdout
for line in mus:
    if 'FAIL' in line:
        sys.stderr.write (line)
# tar up failing modules
with tarfile.open('failing_intermediates.tar','w') as tar:
    for line in mus:
        line_list = line.split()
        if line_list[0] == 'FAIL':
            module_outdir = line_list[2]
            tar.add(module_outdir)


# write full file to output
fid = open(os.path.join(OUTFILES,'%s.summary.usage.txt'%pairID),'w')
fid.write(usageheader)
fid.writelines(mus)
fid.close()



def make_links(subpaths, new_names=None):
    for i,subpath in enumerate(subpaths):
        if not os.path.exists(subpath):
            sys.stderr.write ('file not found: %s'%subpath)
            continue
        if new_names:
            fn = new_names[i]
        else:
            fn = os.path.basename(subpath)
        realsubpath = os.path.realpath(subpath)
        new_path = os.path.join(OUTFILES,fn)
        if os.path.exists(new_path):
            sys.stderr.write('file already exists: %s'%new_path)
            continue
        os.link(realsubpath,new_path) #hard link, to survive export


subpaths = [
    'pipette_jobs/links_for_gnos/oxoG/sample.oxoG.tar.gz',
    'pipette_jobs/links_for_gnos/annotate_failed_sites_to_vcfs/input.oxoG.vcf.gz',
    'pipette_jobs/links_for_gnos/annotate_failed_sites_to_vcfs/input.oxoG.vcf.gz.tbi',
    'pipette_jobs/oxoG/sample.oxoG3.maf.annotated.all.maf.annotated'
]
new_names = [
    'sample.oxoG.supplementary.tar.gz',
    'sample.oxoG.vcf.gz',
    'sample.oxoG.vcf.gz.tbi',
    'sample.oxoG.maf'
]
make_links(subpaths,new_names)





#########################
# end task-specific calls
run('/cga/fh/pcawg_pipeline/utils/monitor_stop.py')
