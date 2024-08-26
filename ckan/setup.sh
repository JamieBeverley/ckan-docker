# using python 3.9 (this is significant, 3.10 won't work with this version of ckan)
python -m venv .venv
source .venv/bin/activate

# this version of ckan uses a deprecated function in setuptools
# must revert back to 45 (which is pretty old...)
# https://github.com/pypa/setuptools/issues/2017#issuecomment-605354361
pip install setuptools==45


# Probably more system deps if needed...
sudo apt-get install libpq-dev


pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.9.11#egg=ckan[requirements]'
pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.9.11#egg=ckan[dev]'
# `pip install -r 'https://raw.githubusercontent.com/ckan/ckan/ckan-2.9.11/dev-requirements.txt'
