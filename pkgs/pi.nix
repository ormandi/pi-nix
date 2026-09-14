# pi ships standalone executables that embed their own JavaScript runtime, so
# this packages the released binary rather than building from source; the
# source build would pull a full node/bun toolchain into the closure.
{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, makeBinaryWrapper
, ripgrep
, fd
}:

let
  version = "0.85.1";

  # Each hash is a digest from the release's SHA256SUMS, converted with
  # `nix hash convert --hash-algo sha256 --to sri <hex>`.
  releases = {
    x86_64-linux = {
      arch = "linux-x64";
      hash = "sha256-SU5Jj0fXTSH0CzOG9qXpIaPUlTGhacq1W72soOof4lo=";
    };
    aarch64-linux = {
      arch = "linux-arm64";
      hash = "sha256-BC0grohe5POxAoFfMoC5YsN3sun7RN5AN5CMxTDq5NQ=";
    };
    x86_64-darwin = {
      arch = "darwin-x64";
      hash = "sha256-rbkYuEViXxhNi+pAjVXqyvIaqHI4eTwPW087lze85is=";
    };
    aarch64-darwin = {
      arch = "darwin-arm64";
      hash = "sha256-1fcOPAz3OY6sI5/QJh7gdNmLe6f2tD/jYX8FLtW3nQY=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  release = releases.${system} or (throw
    "pi: no upstream release binary for ${system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/"
      + "v${finalAttrs.version}/pi-${release.arch}.tar.gz";
    inherit (release) hash;
  };
  sourceRoot = "pi";

  nativeBuildInputs = [ makeBinaryWrapper ]
    ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  installPhase = ''
    runHook preInstall

    # pi resolves its themes, wasm blob and native addons relative to the
    # directory holding the executable, so keep that directory as it ships.
    mkdir -p $out/libexec/pi
    cp -R . $out/libexec/pi

    # pi downloads its own copy of rg and fd when PATH has neither.
    makeWrapper $out/libexec/pi/pi $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [ ripgrep fd ]} \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0

    runHook postInstall
  '';

  meta = {
    description = "Terminal coding agent";
    homepage = "https://pi.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.attrNames releases;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
