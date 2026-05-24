mkdir -p ~/instabooth
cd ~/instabooth

git clone https://github.com/photobooth-app/photobooth-app.git
git clone https://github.com/photobooth-app/photobooth-frontend.git
mkdir photobooth-data

sudo apt install python3.14-venv

cd ~/instabooth/photobooth-frontend
npm install
npm run build

cd ~/instabooth/photobooth-app
python3 -m venv --system-site-packages myenv
source myenv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
python -m pip install pydot

# ---------------------------------------------------
# Run application
# ---------------------------------------------------

cd ~/instabooth/photobooth-data
source ../photobooth-app/myenv/bin/activate
photobooth

Frontend update workflow later:

cd ~/instabooth/photobooth-frontend
npm run build

Backend update workflow:

cd ~/instabooth/photobooth-data
source ../photabooth-app/myenv/bin/activate
photobooth
