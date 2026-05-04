/// Application-wide config constants.
///
/// Set [kAnatomyModelBaseUrl] to the public base URL where the 3D anatomy GLB
/// files are hosted (e.g. Firebase Storage public URL or CDN). The viewer
/// will append the local file name (e.g. `heart.glb`) to this base URL.
///
/// Example: `'https://res.cloudinary.com/<cloud_name>/raw/upload/nurseup/models/'`
///
/// If left empty, the 3D viewer gracefully shows an icon placeholder with
/// instructions, and the rest of the feature (catalog, hotspots metadata,
/// detection) continues to work.
const String kAnatomyModelBaseUrl =
    'https://res.cloudinary.com/dt6vwkajv/raw/upload/nurseup/models/';
