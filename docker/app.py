#!/usr/bin/env python
# -*- coding: utf-8 -*-
from flask import Flask, request, jsonify
import socket
from embed import *

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False


@app.route("/")
def root():
    print("/")
    html = "<h3>Hello {name}!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>"
    return html.format(name=os.getenv("LASER", "world"),
                       hostname=socket.gethostname())


@app.route("/vectorize")
def vectorize():
    start = time.time()
    # todo sentencize the content
    content = request.get_json()['content']
    lang = request.get_json()['lang']


    # todo check to ensure language is in Flora-200 dataset
    if lang is None or not lang:
        lang = "en"

    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        ifname = tmpdir / "content.txt"
        bpe_fname = tmpdir / 'bpe'
        bpe_oname = tmpdir / 'out.raw'
        with ifname.open("w") as f:
            f.write(content)
        if lang != '--':
            tok_fname = tmpdir / "tok"
            Token(str(ifname),
                  str(tok_fname),
                  lang=lang,
                  romanize=True if lang == 'el' else False,
                  lower_case=True,
                  gzip=False,
                  verbose=True,
                  over_write=False)
            ifname = tok_fname
        BPEfastApply(str(ifname),
                     str(bpe_fname),
                     str(bpe_codes_path),
                     verbose=True, over_write=False)
        ifname = bpe_fname
        encodefile(encoder,
                   str(ifname),
                   str(bpe_oname),
                   verbose=True,
                   over_write=False,
                   buffer_size=10000)
        dim = 1024
        x = np.fromfile(str(bpe_oname), dtype=np.float32, count=-1)
        x.resize(x.shape[0] // dim, dim)
        embedding = x
    end = time.time()

    body = {'_number_of_sentences': embedding.shape[0],
            'content': content,
            '_request_time': end - start,
            'embedding': embedding.tolist()}
    return jsonify(body)


if __name__ == "__main__":
    # load encoder
    model_dir = Path(__file__).parent / "LASER" / "models"
    encoder_path = model_dir / "bilstm.93langs.2018-12-26.pt"
    bpe_codes_path = model_dir / "93langs.fcodes"
    print(f' - Encoder: loading {encoder_path}')
    encoder = SentenceEncoder(encoder_path,
                              max_sentences=None,
                              max_tokens=12000,
                              sort_kind='mergesort',
                              cpu=False)

    app.run(debug=True, port=80, host='0.0.0.0')
