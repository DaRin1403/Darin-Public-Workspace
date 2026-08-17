// ============================================================
// anime-theme 图片构建脚本
//
// 作用：把 E:\Deepseek\UI\V1 里的源图压缩成 webp 并内嵌进 lib/client.js。
// 用法（在 profiles\web 目录下运行）：
//     node node_modules\anime-theme\scripts\build-skin.cjs
//
// 四张源图（文件名写死，换图直接覆盖同名文件即可）：
//   Background_Max.png   → ASSETS.background     整页背景（压到 2048 宽）
//   kaguya_1.png         → ASSETS.charBackground 玻璃后立绘（压到 1200 宽，透明度×0.55）
//   Kaguya_Q.png         → ASSETS.charSidebar    侧栏立绘（压到 420 宽）
//   Left_Background.png  → ASSETS.pattern        侧栏花纹（压到 800 宽）
// ============================================================

const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const SRC_DIR = "E:/Deepseek/UI/V1";
const CLIENT_JS = path.join(__dirname, "..", "lib", "client.js");

/** 解码为像素 → 把整图 alpha 乘上透明度 → 重新编码；顺便算出角色的包围盒。 */
async function bakeAlpha(file, opacity, width, quality) {
  const { data, info } = await sharp(file)
    .resize({ width })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  let minX = info.width, minY = info.height, maxX = -1, maxY = -1;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      const i = (y * info.width + x) * 4;
      data[i + 3] = Math.round(data[i + 3] * opacity);
      if (data[i + 3] > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  const buf = await sharp(data, {
    raw: { width: info.width, height: info.height, channels: 4 },
  })
    .webp({ quality })
    .toBuffer();
  return { buf, bbox: { minX, maxX, minY, maxY, w: info.width, h: info.height } };
}

async function main() {
  // ① 整页背景：2048 宽，质量 62
  const bg = await sharp(SRC_DIR + "/Background_Max.png")
    .resize({ width: 2048 })
    .webp({ quality: 62 })
    .toBuffer();

  // ② 玻璃后立绘：1200 宽，透明度 ×0.85（更明显），质量 80
  const cbg = await bakeAlpha(SRC_DIR + "/kaguya_1.png", 0.85, 1200, 80);

  // ③ 侧栏立绘：先裁掉透明边（只留角色本体）→ 340 宽，保持原透明度，质量 82
  const csbRaw = await sharp(SRC_DIR + "/Kaguya_Q.png")
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  let sMinX = csbRaw.info.width, sMinY = csbRaw.info.height, sMaxX = -1, sMaxY = -1;
  for (let y = 0; y < csbRaw.info.height; y++) {
    for (let x = 0; x < csbRaw.info.width; x++) {
      if (csbRaw.data[(y * csbRaw.info.width + x) * 4 + 3] > 10) {
        if (x < sMinX) sMinX = x;
        if (x > sMaxX) sMaxX = x;
        if (y < sMinY) sMinY = y;
        if (y > sMaxY) sMaxY = y;
      }
    }
  }
  const sPad = 24;
  const sLeft = Math.max(0, sMinX - sPad);
  const sTop = Math.max(0, sMinY - sPad);
  const sW = Math.min(csbRaw.info.width - sLeft, (sMaxX - sMinX) + sPad * 2);
  const sH = Math.min(csbRaw.info.height - sTop, (sMaxY - sMinY) + sPad * 2);
  const csb = await sharp(SRC_DIR + "/Kaguya_Q.png")
    .extract({ left: sLeft, top: sTop, width: sW, height: sH })
    .resize({ width: 340 })
    .webp({ quality: 82 })
    .toBuffer();

  // ④ 侧栏花纹：800 宽，质量 76
  const pat = await sharp(SRC_DIR + "/Left_Background.png")
    .resize({ width: 800 })
    .webp({ quality: 76 })
    .toBuffer();

  // 花纹平均亮度（供调"白纱"浓度参考；0 黑 ~ 255 白）
  const { data: pd } = await sharp(SRC_DIR + "/Left_Background.png")
    .resize({ width: 120 })
    .greyscale()
    .raw()
    .toBuffer({ resolveWithObject: true });
  let sum = 0;
  for (let i = 0; i < pd.length; i++) sum += pd[i];

  // 生成替换块
  const entries = {
    background: bg,
    charBackground: cbg.buf,
    charSidebar: csb,
    pattern: pat,
  };
  const lines = Object.entries(entries).map(
    ([key, buf]) => '      ' + key + ': "data:image/webp;base64,' + buf.toString("base64") + '",'
  );
  const block = "/*ASSETS-START*/\n" + lines.join("\n") + "\n    /*ASSETS-END*/";

  const src = fs.readFileSync(CLIENT_JS, "utf8");
  if (!src.includes("/*ASSETS-START*/")) {
    throw new Error("client.js 里没有 ASSETS 标记区，无法替换");
  }
  const next = src.replace(/\/\*ASSETS-START\*\/[\s\S]*?\/\*ASSETS-END\*\//, block);
  fs.writeFileSync(CLIENT_JS, next);

  const kb = (n) => (n / 1024).toFixed(0) + "KB";
  console.log("✅ 构建完成，已写入 lib/client.js");
  console.log("   背景:", kb(bg.length), "| 背景立绘:", kb(cbg.buf.length), "| 侧栏立绘:", kb(csb.length), "| 花纹:", kb(pat.length));
  console.log("   client.js 总大小:", kb(fs.statSync(CLIENT_JS).size));
  console.log("   立绘包围盒(左,右,上,下 / 宽x高):",
    [cbg.bbox.minX, cbg.bbox.maxX, cbg.bbox.minY, cbg.bbox.maxY].join(","),
    "/", cbg.bbox.w + "x" + cbg.bbox.h);
  console.log("   花纹平均亮度(0-255):", sum / pd.length);
}

main().catch((e) => {
  console.error("❌ BUILD FAIL:", e.message);
  process.exit(1);
});
