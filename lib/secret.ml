let nonce_size = 12

let encrypt_base64 key contents =
  assert (String.length contents > 0);
  let key = Cstruct.of_string key in
  let key = Mirage_crypto.Chacha20.of_secret key in
  let nonce = Mirage_crypto_rng.generate nonce_size in
  let encrypted =
    Mirage_crypto.Chacha20.authenticate_encrypt ~key ~nonce
      (Cstruct.of_string contents)
  in
  Cstruct.concat [ nonce; encrypted ]
  |> Cstruct.to_string
  |> Base64.(encode_string ~pad:false ~alphabet:uri_safe_alphabet)

let decrypt_base64 key contents =
  assert (String.length contents > 0);
  let key = Cstruct.of_string key in
  let key = Mirage_crypto.Chacha20.of_secret key in
  let contents =
    Base64.(decode_exn ~pad:false ~alphabet:uri_safe_alphabet contents)
    |> Cstruct.of_string
  in
  let nonce = Cstruct.sub contents 0 nonce_size in
  Cstruct.sub contents nonce_size (Cstruct.length contents - nonce_size)
  |> Mirage_crypto.Chacha20.authenticate_decrypt ~key ~nonce
  |> function
  | Some s -> Cstruct.to_string s
  | None -> failwith "Unable to decrypt contents"
