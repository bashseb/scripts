scripts
=======

* recOe1.sh: Records from oe1 webstream and saves it into a file `<name-string>-<date>.mp3`
 
  Usage: `./recOe1.sh <length in seconds> <name-string (e.g Pasticcio)>`

  If the `<name-string>` matches a title on `oe1.orf.at/programm`, then also the abstract is saved in `<name-string>-<date>.txt`
  
  Configure the script variables (optional):
  
  * `TARGET_DIR`: path to save directory, default `~/oe1/`
  
  OPTIONAL (leave empty if files are not made publicly accessible):

  * `WWW_DIR`: directory of a path of the webserver (e.g. `/var/www/oe1`, has to be owned by the executing user)
  * `WWW_BASE_URL` web address of webserver, e.g. `http://myserver.at/oe1`. This is where links are made available.
  
  Conveniently use this is a `cronjob`, e.g. 
   ```
# Matrix                                                                        
# 30 min, recording 31 * 60 secs                                                
29 22 * * 0 : Matrix Computer und neue Medien 30min; sleep 40; /home/seb/scripts/recOe1.sh 1860 Matrix
   ```
