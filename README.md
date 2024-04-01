# Instructions

Install direnv: `sudo apt install direnv`

Run it: `eval "$(direnv hook bash)"`

```sh
cp .envrc.sample .envrc
# edit values in .envrc
direnv allow .
```

1. (optional) install virrtualenv (sudo apt install virtualenv)
2. (optional) create a virtual environment `virtualenv -p python3 venv`
3. (optional) activate the virtual environment `source venv/bin/activate`
4. `pip3 install -r requirements.txt`
5. `python3 main.py`

#### Expected result checksum
```
a167c239c5faad760c74970307682ffeb3b09957101d6a7352ee8ea0ebaaa93d
```