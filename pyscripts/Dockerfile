FROM continuumio/anaconda3
COPY environment.yml .
COPY quimbi_h5_parser.py .
RUN conda env create -f environment.yml
ENV PATH /opt/conda/envs/quimbi/bin:$PATH
RUN /bin/bash -c "source activate quimbi"
ENTRYPOINT ["python", "quimbi_h5_parser.py"]