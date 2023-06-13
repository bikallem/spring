open Cmdliner

let ohtml_cmd =
  let doc = "Generates Spring Ohtml views (.ml) from .ohtml files" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "ohtml" ~version:"%%VERSION%%" ~doc ~man in
  let ohtml_dir_arg =
    let doc = "directory where .ohtml files are located" in
    Arg.(required & pos 0 (some' string) None & info [] ~docv:"OHTML_DIR" ~doc)
  in
  let ohtml dir_path =
    let generate_file filepath =
      let fun_name = Filename.remove_extension filepath in
      let doc = Ohtml.parse_doc filepath in
      Out_channel.with_open_gen
        [ Open_wronly; Open_creat; Open_trunc; Open_text ]
        0o644 (fun_name ^ ".ml") (fun out ->
          let write_ln s = Out_channel.output_string out ("\n" ^ s) in
          Ohtml.gen_ocaml ~write_ln doc);
      Printf.printf "\nGenerating view: %s" filepath
    in
    Sys.readdir dir_path
    |> Array.to_list
    |> List.filter (fun x -> Filename.extension x = ".ohtml")
    |> List.iter (fun x ->
           let filename = dir_path ^ Filename.dir_sep ^ x in
           generate_file filename)
  in
  let ohtml_t = Term.(const ohtml $ ohtml_dir_arg) in
  Cmd.v info ohtml_t

let key_cmd =
  let doc =
    "Generates 'master.key' file which contains a key value that is used to \
     encrypt/decrypt data in spring."
  in
  let man =
    [ `S Manpage.s_bugs; `P "Bug reports to github.com/bikallem/spring/issues" ]
  in
  let info = Cmd.info "key" ~version:"%%VERSION%%" ~doc ~man in
  let key_cmd_arg =
    let doc = "name of the master key file. Default is 'master.key'." in
    Arg.(
      value
      & opt string "master.key"
      & info [ "f"; "file" ] ~docv:"MASTER_KEY_FILENAME" ~doc)
  in
  let master_key filename =
    let key =
      Eio_main.run @@ fun env ->
      Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env
      @@ fun () ->
      Mirage_crypto_rng.generate 32
      |> Cstruct.to_string
      |> Base64.(encode_string ~pad:false)
    in
    Out_channel.with_open_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ]
      0o644 filename (fun out -> Out_channel.output_string out key)
  in
  let key_t = Term.(const master_key $ key_cmd_arg) in
  Cmd.v info key_t

let spring_cmd =
  let doc = "Spring" in
  let man =
    [ `S Manpage.s_bugs
    ; `P "Bug reports to github.com/bikallem/spring/issues."
    ]
  in
  let info = Cmd.info "spring" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.group info [ ohtml_cmd; key_cmd ]

let main () = exit (Cmd.eval spring_cmd)
let () = main ()
