# <center> Laser Embeddings w/ Docker Image API v1.2</center>
---

###### <center>+ LangDetect and LangId for sentence-level language detection and NLTK and Stanza for language-specific sentence tokenization.</center>
---

<center><b>Created by:<b></center></br>
<center>Kevan White, Sr. Data Scientist (thyripian)</center></br></br>
<center>Release Date: 22 June 2023</center></br>


#### <center>Notes:</center>
This python module <i>(located in the notebook in the 'python' directory)</i> relies on the LASER_embeddings repository and associated Docker Image to run. Failure to clone the repository to your local machine and build the Docker Image will result in failed attempts to process the data.</br></br>
If you have cloned the repository, but are unaware of how to build the Docker Image:</br>
- Install Docker Desktop (will require a system restart or log-out)
- Using a Bash terminal (such as GitBASH), navigate to the directory of the cloned repository containing the .dockerfile
- Run the command:   docker build -t LASER_embeddings -f LASER_embeddings.dockerfile .
- Once the Image is built, you may need to restart the computer and Docker Desktop.
- Reopen the Bash terminal and navigate back to the same directory.
- Run the command:   docker run -it -p 8080:80 --gpus 0 LASER_embeddings
- Once this last command is run, you can start and stop the Docker Image in the Docker Desktop GUI for all future use.</br>
