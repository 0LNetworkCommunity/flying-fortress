# Instructions


# Python Setup
Setup virtual env linux:
1. (optional) install virrtualenv (sudo apt install virtualenv)
  MacOs:
2. (optional) create a virtual environment `virtualenv -p python3 venv`
3. (optional) activate the virtual environment `source venv/bin/activate`

Setup virtual env MacOs
```
python3 -m venv ./.libra_env
source ./.libra_env/bin/activate
python3 -m pip install -r requirements.txt
```

# Use environment variables

### Add credentials

```
cp .envrc.sample .envrc
# edit values in .envrc (see details here: https://pastebin.com/yZjpAYqj)
```

# Run it
```
python3 main.py
```
