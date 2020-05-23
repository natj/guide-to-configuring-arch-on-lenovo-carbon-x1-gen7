default:
	gh-md-toc --insert README.md
	rm README.md.orig.*
	rm README.md.toc.*
	echo 'ready!'
