default: help

SEMESTER = V2016
REPORT_WRITERS = 8

# DAV mounted fui vortex folder (not mounted automatically):
MOUNT_PATH = /Volumes/fui
# MOUNT_PATH = Z:/fui
# MOUNT_PATH = /mnt/fui

install-mac: # mac only :)
	brew install python3
	brew install phantomjs
	brew install rename
	brew install pandoc
	# TODO: Add LaTeX installation
	pip3 install -r requirements.txt

install-linux:
	apt install python3
	apt install python3-pip
	apt-get install phantomjs
	apt install pandoc
	apt-get install texlive-full
	pip3 install -r requirements.txt

usernames:
	python3 fui_kk/get_usernames.py

download:
	python3 fui_kk/download_reports.py -u fui
	python3 fui_kk/sort_downloads.py --delete -i downloads -o data -e "(INF9)|(testskjema)|(\*\*\*)|(XXX)"
	@echo "Warning: Please delete the downloads folder once per semester"
	@echo "         after closing the forms, to ensure that up to date"
	@echo "         reports are downloaded. (The download script will not"
	@echo "         redownload forms with ID in downloaded.txt)"

sample_data:
	git submodule init
	git submodule update
	cp -r sample_data data

responses:
	python3 fui_kk/responses.py -s all

scales:
	python3 fui_kk/scales.py all

json:
	python3 fui_kk/course.py data
	python3 fui_kk/semester.py
	python3 fui_kk/courses.py

tex:
	# rename -v -f -S inf INF ./data/*/inputs/md/* # Only on mac
	perl -i.bak -pe 's/\x61\xCC\x8A/\xC3\xA5/g' ./data/*/inputs/md/*.md
	find ./data -type f -name *.md.bak -delete
	bash ./fui_kk/tex.sh $(SEMESTER)
	python3 fui_kk/participation_summary.py $(SEMESTER)
	python3 fui_kk/tex_combine.py -s $(SEMESTER)

pdf: tex
	bash ./fui_kk/pdf.sh $(SEMESTER)

plots:
	python3 fui_kk/plot_courses.py $(SEMESTER)

all: responses scales json plots tex pdf web

assign-courses:
	python3 fui_kk/course_divide.py $(REPORT_WRITERS) $(SEMESTER) > REPORT_WRITERS.json
	cat REPORT_WRITERS.json
	@echo "The assignments above are also saved to 'REPORT_WRITERS.json'"

open:
	open data/$(SEMESTER)/outputs/report/fui-kk_report*.pdf

web:
	bash ./fui_kk/web.sh $(SEMESTER)
	python3 ./fui_kk/web_reports.py data/$(SEMESTER)

web-preview: web
	@echo "---------------------------------------------"
	@echo " WARNING: Do NOT commit changes to ./docs if"
	@echo " you are working with real data!"
	@echo "---------------------------------------------"
	rm -rf ./docs
	mkdir ./docs
	cp -r ./data/$(SEMESTER)/outputs/web/upload/$(SEMESTER)/* ./docs
	python3 ./fui_kk/adapt_preview_html.py

upload_raw:
	@echo "Mount fui folder to MOUNT_PATH using DAV before running:"
	python3 fui_kk/upload_reports.py -v --input ./data --output $(MOUNT_PATH)/KURS/ --semester $(SEMESTER)

score:
	python3 ./fui_kk/score.py $(SEMESTER)

clean:
	find ./data -type d -name "outputs" -exec rm -rf {} +
	rm -rf ./downloads

super-clean:
	find ./data -type d -name "outputs" -exec rm -rf {} +
	rm -rf ./data/$(SEMESTER)/resources
	rm -rf ./downloads


venv:
	python3 -m venv venv
	# Activate virtual environment by running "source venv/bin/activate" in your shell

pip-install:
	pip install -r requirements.txt

pip3-install:
	pip3 install -r requirements.txt

help:
	@echo "Available targets:"
	@echo "install-mac"
	@echo "download"
	@echo "sample_data"
	@echo "all"
	@echo "scales"
	@echo "json"
	@echo "plots"
	@echo "tex"
	@echo "pdf"
	@echo "web"
	@echo "web-preview"

.PHONY: default install-mac download sample_data responses scales json tex pdf plots all open web upload_raw score clean help venv pip-install pip3-install usernames
