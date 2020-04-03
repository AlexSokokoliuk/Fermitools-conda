export condaname="fermitools"

# REPOMAN! #
# Syntax Help:
# To checkout master instead of the release tag add '--develop' after checkout
# To checkout arbitrary other refs (Tag, Branch, Commit) add them as a space
#   delimited list after 'conda' in the order of priority.
#   e.g. ScienceTools highest_priority_commit middle_priority_ref branch1 branch2 ... lowest_priority
#repoman --remote-base https://github.com/fermi-lat checkout --force --develop ScienceTools conda

export OUTPUT=${PREFIX}

# Add optimization
export CFLAGS="-O2 ${CFLAGS}"
export CXXFLAGS="-O2 ${CXXFLAGS}"

# Add rpaths needed for our compilation
export LDFLAGS="${LDFLAGS} -Wl,-rpath,${PREFIX}/lib,-rpath,${PREFIX}/lib/root,-rpath,${PREFIX}/lib/${condaname}"

if [ "$(uname)" == "Darwin" ]; then

    #std=c++11 required for use with the Mac version of CLHEP in conda-forge
    export CXXFLAGS="-std=c++11 ${CXXFLAGS}"
    export LDFLAGS="${LDFLAGS} -headerpad_max_install_names"
    echo "Compiling without openMP, not supported on Mac"

else

    # This is needed on Linux
    export CXXFLAGS="-std=c++11 ${CXXFLAGS}"
    export LDFLAGS="${LDFLAGS} -fopenmp"

fi

ln -s ${cc} ${PREFIX}/bin/gcc

ln -s ${CXX} ${PREFIX}/bin/g++

scons -C ScienceTools \
      --site-dir=../SConsShared/site_scons \
      --conda=${PREFIX} \
      --use-path \
      -j ${CPU_COUNT} \
      --with-cc="${CC}" \
      --with-cxx="${CXX}" \
      --ccflags="${CFLAGS}" \
      --cxxflags="${CXXFLAGS}" \
      --ldflags="${LDFLAGS}" \
      all

rm -rf ${PREFIX}/bin/gcc

rm -rf ${PREFIX}/bin/g++

# Remove the links to fftw3
rm -rf ${PREFIX}/include/fftw

# Install in a place where conda will find the ST

# Libraries
mkdir -p $OUTPUT/lib/${condaname}
if [ -d "lib/debianstretch/sid-x86_64-64bit-gcc48" ]; then
    echo "Subdirectory Found! (Lib)"
    pwd
    ls lib/
    ls lib/debianstretch/
    ls lib/debianstretch/sid-x86_64-64bit-gcc48/
    \cp -R lib/*/*/* $OUTPUT/lib/${condaname}
else
    echo "Subdirectory Not Found! (Lib)"
    \cp -R lib/*/* $OUTPUT/lib/${condaname}
fi

# Headers
mkdir -p $OUTPUT/include/${condaname}
if [ -d "include/debianstretch/sid-x86_64-64bit-gcc48" ]; then
    echo "Subdirectory Found! (Include)"
    \cp -R include/*/* $OUTPUT/include/${condaname}
else
    echo "Subdirectory Not Found! (Include)"
    \cp -R include/* $OUTPUT/include/${condaname}
fi

# Binaries
mkdir -p $OUTPUT/bin/${condaname}
if [ -d "exe/debianstretch/sid-x86_64-64bit-gcc48" ]; then
    echo "Subdirectory Found! (bin)"
    \cp -R exe/*/*/* $OUTPUT/bin/${condaname}
else
    echo "Subdirectory Not Found! (bin)"
    \cp -R exe/*/* $OUTPUT/bin/${condaname}
fi

# Python packages
# Figure out the path to the site-package directory
export sitepackagesdir=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

echo "OUTPUT=$OUTPUT"
echo "sitepackagesdir=$sitepackagesdir"

# Create our package there
mkdir -p $sitepackagesdir/${condaname}
# Making an empty __init__.py makes our directory a python package
echo "" > $sitepackagesdir/${condaname}/__init__.py
# Copy all our stuff there
\cp -R python/* $sitepackagesdir/${condaname}
# There are python libraries that are actually under /lib, so let's
# add a .pth file so that it is not necessary to setup PYTHONPATH
# (which is discouraged by conda)
echo "$PREFIX/lib/${condaname}" > $sitepackagesdir/${condaname}.pth
# In order to support things like "import UnbinnedAnalysis" instead of
# "from fermitools import UnbinnedAnalysis" we need to
# also add the path to the fermitools package
echo "${sitepackagesdir}/fermitools" >> $sitepackagesdir/${condaname}.pth

# Pfiles
mkdir -p $OUTPUT/share/${condaname}/syspfiles
\cp -R syspfiles/* $OUTPUT/share/${condaname}/syspfiles

# Xml
mkdir -p $OUTPUT/share/${condaname}/xml
\cp -R xml/* $OUTPUT/share/${condaname}/xml

# Data
mkdir -p $OUTPUT/share/${condaname}/data
\cp -R data/* $OUTPUT/share/${condaname}/data

# fhelp
mkdir -p $OUTPUT/share/${condaname}/help
\cp -R fermitools-fhelp/* $OUTPUT/share/${condaname}/help
rm -f $OUTPUT/share/${condaname}/help/README.md #Remove the git repo README

# Copy also the activate and deactivate scripts
mkdir -p $OUTPUT/etc/conda/activate.d
mkdir -p $OUTPUT/etc/conda/deactivate.d

\cp $RECIPE_DIR/activate.sh $OUTPUT/etc/conda/activate.d/activate_${condaname}.sh
\cp $RECIPE_DIR/deactivate.sh $OUTPUT/etc/conda/deactivate.d/deactivate_${condaname}.sh

\cp $RECIPE_DIR/activate.csh $OUTPUT/etc/conda/activate.d/activate_${condaname}.csh
\cp $RECIPE_DIR/deactivate.csh $OUTPUT/etc/conda/deactivate.d/deactivate_${condaname}.csh
