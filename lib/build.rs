extern crate prost_build;

fn main() {
    prost_build::compile_protos(&["proto/flouze.proto"],
                                &["proto/"]).unwrap();
}
