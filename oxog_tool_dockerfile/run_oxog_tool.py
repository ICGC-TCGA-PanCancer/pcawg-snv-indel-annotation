import subprocess
import os
import sys
import tarfile
import shutil
import argparse

def run(cmd):
    print(cmd)
    subprocess.check_call(cmd,shell=True)

run('/cga/fh/pcawg_pipeline/utils/monitor_start.py')

# start task-specific calls
##########################
parser = argparse.ArgumentParser()
parser.add_argument('--inputDir')
parser.add_argument('--pairID')
parser.add_argument('--bamName')
# parser.add_argument('--baiName')
parser.add_argument('--oxoqScore')
parser.add_argument('--refDataDir')
parser.add_argument('--vcfs', nargs='+')
args = parser.parse_args()
argvars = vars(args)

#copy wdl args to python vars
inputDir = argvars['inputDir']

pairID = argvars['pairID']
bam_tumor = inputDir + '/' + argvars['bamName']
#bam_tumor_index = inputDir + '/' + argvars['baiName']
oxoq = argvars['oxoqScore']

vcfs = argvars['vcfs']
# for vcf in argvars['vcfs']:
#     vcfs += vcf #(' ' + inputDir + '/' + vcf )

refdata1=argvars['refDataDir']

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

#run the pipette synchronous runner to process the test data
cmd_str = 'python3 %s/pipetteSynchronousRunner.py '%PIPETTE_SERVER_DIR + ' '.join([COMMDIR,OUTDIR,PIPELINE,COMMDIR,OUTDIR,pairID,bam_tumor,oxoq,'--ref',refdata1,vcfs])
print('executing command: '+cmd_str+'\n')
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
    print('subpaths: ' + str(subpaths))
    print('new names: ' + str(new_names))
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
        # make sure everyone *outside* the container can read the output files.
        os.chmod(realsubpath, 0o666)
        os.chmod(new_path, 0o666)

subpaths = ['/var/spool/cwl/pipette_jobs/links_for_gnos/oxoG/'+pairID+'.oxoG.tar.gz',
            '/var/spool/cwl/pipette_jobs/oxoG/'+pairID+'.oxoG3.maf.annotated.all.maf.annotated']

new_names = [pairID+'.oxoG.supplementary.tar.gz',
            pairID+'.oxoG.maf']

for vcf in argvars['vcfs']:
    path_to_oxog_vcf = vcf.replace('.vcf.gz','.oxoG.vcf.gz')
    path_to_oxog_tbi = vcf.replace('.vcf.gz','.oxoG.vcf.gz.tbi')
    subpaths.extend(['/var/spool/cwl/pipette_jobs/links_for_gnos/annotate_failed_sites_to_vcfs/'+path_to_oxog_vcf,
                    '/var/spool/cwl/pipette_jobs/links_for_gnos/annotate_failed_sites_to_vcfs/'+path_to_oxog_tbi])
    new_names.extend([path_to_oxog_vcf,path_to_oxog_tbi])


make_links(subpaths,new_names)

#########################
# end task-specific calls
run('/cga/fh/pcawg_pipeline/utils/monitor_stop.py')
