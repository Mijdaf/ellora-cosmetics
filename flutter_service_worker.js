'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "ff538f33b80f68eb4d924ad4ac75944f",
".git/config": "b1475a9f2ea8e1ff1b4f3ebdf8b8b3d5",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "c08debdf8114c91e9366b70014552cc8",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "7610484734136d7fe70118fe3765d273",
".git/logs/refs/heads/gh-pages": "7610484734136d7fe70118fe3765d273",
".git/logs/refs/remotes/origin/gh-pages": "4a9882af1bc946b2506ce88abd5df075",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/03/dde7baa67531d2db70daa394007ee264814c95": "db62ebd67f3712ec8339e15a9940a2b6",
".git/objects/04/53f0acd852003660258e8325618525080a579e": "642bef93dd37f6b3c2d2d59330655ead",
".git/objects/05/f7e4fab08ce508f927c4683ed0d1f17078881a": "2609831ac13589761332c032f081c2ed",
".git/objects/09/dbcd763415963bdf7747ff17a35164ebe679a4": "714513ffa498c4c25ed44b8655310788",
".git/objects/0b/da228ade88b0bb5aac7da2c881d0c3f64d0817": "02c3f38c13f78243f1c52e7cbb8200cb",
".git/objects/0e/fe60e7dcc624150a350817ead465337fe2354d": "7158aad1c2bdcc7352ba6f49a6b9d297",
".git/objects/19/82f38ab21303459aa1155265052ca599fa58d1": "a293dd17a2e66acae6527c2621b5e28f",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/26/503f066a28a2746a9ba40d55f7c1df1bf1ebf0": "100a6dcb9d228b12fc2ed77f6cef60df",
".git/objects/26/70aa0f3ad531beb0ab9bc0b35468c2d4bb41d7": "e1174358e08ffd54fd6911bb1dab5be6",
".git/objects/27/9ce759a36424cff5583d70d40e6bf63ab032d5": "cea1376532abd117e812c7a9dad89a11",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/2b/e9df799f265485090583e9f36f04ff844cedcf": "3776911449f715e0fd5ac70e8a633568",
".git/objects/33/c3f750a699387c744f37b1e2db63a145aac48f": "24ea966671142e50f614925a4f6e0789",
".git/objects/4c/8e9d1d3eb6555f1b7a16925321c8fa038da23b": "9355e42210ec2657c14b3fc656d8c29a",
".git/objects/4d/0b6cb8652c5988a0043553969c76f3949fdc91": "bd0291fa0429428cec3de49db71e8d7c",
".git/objects/4d/20e1b644b0cac7d062af91cef24756250dfa86": "a6afba434297c6c5e98c41d55a2d2851",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/5e/f7669e388c61227a66d14242f1fdefd6b2758b": "31d9e6812a0d29341925148f2dbf5bed",
".git/objects/63/6625a1504c8d13501835fb1ad8c854eb4797bc": "f439630e84b230467afc678af4a3149d",
".git/objects/64/6206ece8393a1af887128fc321a5a0e981b809": "2284f810286f9b8d99fd23a5af45be47",
".git/objects/65/63d44ab3d6bf8ecace9abc8ed6c1a4b5976b4f": "9b5ca43193cdcf08f0c0674cd572c55d",
".git/objects/6a/484c9e590f5d9d04fce56be4bed4c9e9510a40": "f719396113a833fb5d3b74f8652500d3",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7d/a7c3c61bc8cb00c6390bd7121a1a7ebce83a1b": "1477a0fde9d038fa1d4fd611f76d7f0f",
".git/objects/85/c6e77c7da6dcd82a3732be994bee9654f81bb9": "8f280ac0d87823598c86cb93a01ebc0b",
".git/objects/89/96dbd50d930e4f8a8adf8775f8964d980ed6ba": "5289598c1dede28ac26c4772d1637c01",
".git/objects/8a/1be5af99f92602ff8b92a3b454c7d78c37b88f": "23bd11d6849512e7faff6ae2674c0cd8",
".git/objects/8c/8bff92630891f6d7aeb729ad10d5ee3760c2b8": "81fe79525aa13edc7df2e0ac2f016633",
".git/objects/8e/dabcb1717a83e6c06a787bbfa7f82110483579": "bb9d2a520f6e9ebb1a3c963c112bb57c",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/a2/82113fa37af0b5cd8ddd11216bde06e6f87fce": "6dbd93f7138db218181c73480f040963",
".git/objects/a2/b349a12ea14a1b513cd22a7b1b0b0d53cc167d": "d4641c7b9af4553f20840c00cbd68569",
".git/objects/a3/379db4b1cde380b226f8c78b3ae6515cf80652": "39d43959c9b162d27505b14b0ee51002",
".git/objects/a5/90f5c3e4902a7cb10f4bbc5da0e65e667f7950": "fb4b949d2276d198ee88eef0e3fde2b1",
".git/objects/a6/ac24831fdfc8ad34fb93f49c02600e46b2a372": "362aca22ccbd92ce2aaf6717e20382e5",
".git/objects/b5/75f1de74d841bf5473aaf5166d248d3accaf1b": "7fb1bdaedee24f3c2d412299e690ca6f",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/c0/e86b0bfc7b902c485699953dee878f290f575b": "3b52a9dab0729dfae27d169a9b146ce2",
".git/objects/c2/8302b6e375de78c9eda81a049a9e3262aa3304": "6ffc53925bc543a44d3394490fa53a66",
".git/objects/c3/0ad104723a0e6e00e54768626cb02c5fdf6aee": "ebeda149e3a8df1ed446e8d8dc30fbfe",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/e1/85d7a6d1c8067d0ecbfd8dbc5fb42bd21c2a25": "185f160685f999bee13d8f838364c1d7",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/refs/heads/gh-pages": "35b5d3367b9a5623bd3767a4d0c02f00",
".git/refs/remotes/origin/gh-pages": "35b5d3367b9a5623bd3767a4d0c02f00",
"assets/AssetManifest.bin": "11b5d570843ef1cda9ed77adf889fd0a",
"assets/AssetManifest.bin.json": "5619702450ba09ec4e8b18e6c4efa82b",
"assets/AssetManifest.json": "4957c14fb7920b50ea54087d001a6f63",
"assets/assets/fonts/Cairo-Bold.ttf": "a570f43aac3c3752f85bc4583a1ea5dd",
"assets/assets/fonts/Cairo-Medium.ttf": "92c68c96d023725c3ce0bec707afcce5",
"assets/assets/fonts/Cairo-Regular.ttf": "e85e23c4a85f83a88082f3d945cea399",
"assets/assets/fonts/Cairo-SemiBold.ttf": "63c0cfa048fe77ac997906308c230624",
"assets/assets/fonts/Poppins-Bold.ttf": "92934d92f57e49fc6f61075c2aeb7689",
"assets/assets/fonts/Poppins-Medium.ttf": "20aaac2ef92cddeb0f12e67a443b0b9f",
"assets/assets/fonts/Poppins-Regular.ttf": "09acac7457bdcf80af5cc3d1116208c5",
"assets/assets/fonts/Poppins-SemiBold.ttf": "2c63e05091c7d89f6149c274971c7c23",
"assets/assets/icons/instagram.svg": "8e8d554c282bd215a21fa0bcf813f097",
"assets/assets/images/logo.jpg": "847b9273dd17168931825eaaa6af7ec5",
"assets/assets/images/logo_note.txt": "eac9478fcb07bb7f83b7aa5e87c21501",
"assets/FontManifest.json": "211cc0eba9e17896805b97402871153a",
"assets/fonts/MaterialIcons-Regular.otf": "d7b0b6a14fb40bb6cacb6c09b44462f1",
"assets/NOTICES": "8e941a1e36575c9e7add838f78c30149",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "08f00a414b23c160765731114848e960",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "218cc86eca2cbc90fed2998435c2d0d3",
"icons/Icon-192.png": "843648c12b8058d31871edb3f2673cdf",
"icons/Icon-512.png": "ebcc4fbf08f6734338cfb1f5a79c7d9a",
"icons/Icon-maskable-192.png": "843648c12b8058d31871edb3f2673cdf",
"icons/Icon-maskable-512.png": "ebcc4fbf08f6734338cfb1f5a79c7d9a",
"index.html": "4afd6cd9eb5a3348fcb3aa3389f4e82d",
"/": "4afd6cd9eb5a3348fcb3aa3389f4e82d",
"main.dart.js": "8e2b3daddf6ee0580285a9717668b7bd",
"manifest.json": "4cbbcd605f903c804baf06ba9c667797",
"version.json": "da04607164880f506dcdc1ad3056d84d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
