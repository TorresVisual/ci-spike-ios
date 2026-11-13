use chacha20poly1305::{aead::{Aead, KeyInit}, XChaCha20Poly1305, XNonce};

/// Encrypt then decrypt a fixed message; returns 1 on success. Exercises a real crypto dependency in the static lib.
#[no_mangle]
pub extern "C" fn spike_selftest() -> i32 {
    let cipher = XChaCha20Poly1305::new(&[7u8; 32].into());
    let nonce = XNonce::from([9u8; 24]);
    let ct = cipher.encrypt(&nonce, b"hello".as_ref()).unwrap();
    (cipher.decrypt(&nonce, ct.as_ref()).unwrap() == b"hello") as i32
}
