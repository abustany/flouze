extern crate prost_build;

fn main() {
    let mut config = prost_build::Config::new();
    config.type_attribute(".", "#[derive(Serialize, Deserialize)]");
    config.compile_protos(&["proto/flouze.proto"], &["proto/"]).unwrap();
}
