{ rustPlatform, fetchFromGitHub, lib }:

rustPlatform.buildRustPackage {
  pname = "rusty-rain";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "cowboy8625";
    repo = "rusty-rain";
    rev = "v0.5.0";
    hash = "sha256-zjASQSXBlaYBId4Cye+7I52dCaOxWwmR8svOeZ4Ra1A=";
  };

  # Upstream skipper Cargo.lock; generert lokalt med cargo 1.94.
  cargoLock.lockFile = ./Cargo.lock;
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  # Snapshot-test (insta) feiler i sandbox - hopp over.
  doCheck = false;

  meta = {
    description = "Cross platform CMatrix-like rain animation";
    homepage = "https://github.com/cowboy8625/rusty-rain";
    license = lib.licenses.mit;
    mainProgram = "rusty-rain";
  };
}
