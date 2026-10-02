// Compress an evidence photo client-side before it's uploaded to Supabase
// Storage. Recommended settings for this use case (survey evidence
// screenshots/photos, not archival-quality images):
//   - max dimension 1280px — still readable for reviewing evidence on
//     screen, phone screenshots/photos are routinely several times larger
//     than needed here
//   - JPEG quality 0.65 — some visible softening on zoom, but keeps
//     storage usage low across many submissions
export async function compressImage(file, { maxDimension = 1280, quality = 0.65 } = {}) {
  if (!file.type.startsWith("image/") || file.type === "image/gif") {
    return file; // animated GIFs would lose their animation if re-encoded
  }

  try {
    const bitmap = await createImageBitmap(file);
    let { width, height } = bitmap;

    if (width > maxDimension || height > maxDimension) {
      const scale = maxDimension / Math.max(width, height);
      width = Math.round(width * scale);
      height = Math.round(height * scale);
    }

    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(bitmap, 0, 0, width, height);

    const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", quality));
    bitmap.close?.();

    if (!blob || blob.size >= file.size) return file; // compression didn't help, keep original

    const newName = file.name.replace(/\.\w+$/, "") + ".jpg";
    return new File([blob], newName, { type: "image/jpeg" });
  } catch {
    return file; // any decoding failure — fall back to the original file
  }
}
