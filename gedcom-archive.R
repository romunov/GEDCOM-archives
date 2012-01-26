# Toy project for downloading genealogy archives from genealogyforum.com
# TODO: test sapply to run in parallel

# Ljubjana, 26.1.2012
# Roman Luštrik (romunov@gmail.com)

library(XML)
library(RCurl)
library(stringr)

# download main archive site
uerel <- "http://www.genealogyforum.com/gedcom/"
gns <- getURL(uerel)
gns <- readLines(textConnection(gns))

# find links to GEDCOM archives
libs <- gns[grepl(">GEDCOM Library", gns)] # subset only elements with this string
libs <- unlist(str_extract_all(libs, "gedcom[[:digit:]]+|gedcom[[:digit:]]+a|gedcom[[:digit:]]+b")) # extract page names
libs <- libs[!(grepl("9a", libs, perl = TRUE))] # remove 9a - if you want 9a, remove/comment this line

# create links to archives
url.index <- paste(uerel, libs, sep = "") 

# visit every archive link...
lapply(X = url.index, FUN = function(add) {
			
			# append index.html to the archive url
			add.index <- paste(add, "index.html", sep = "/")
			
			# and download page
			fetched.url <- getURL(add.index)
			read.url <- readLines(textConnection(fetched.url))
			
			# extract page urls linking to sub-pages
			url.address <- unlist(str_extract_all(read.url,
							"ged[[:digit:]]+\\.htm|gedr[[:digit:]]+\\.htm"))
			
			# glue the main url with the subpage name
			url.subpage <- paste(add, url.address, sep = "/")
			
			# visit every subpage, find a path to a .ged or .zip file
			# and download the name
			sapply(X = url.subpage, FUN = function(z) {
						sub.fetched <- getURL(z)
						sub.fetched <- readLines(textConnection(sub.fetched))
						
						sub.extracted <- unlist(str_extract_all(sub.fetched, # extract file path
										"http://.+\\.ged|http://.+\\.zip"))
						
						# quiet = TRUE to suppress status messages and the _progress_ bar
						download.file(sub.extracted, destfile = basename(sub.extracted))
					})
		})