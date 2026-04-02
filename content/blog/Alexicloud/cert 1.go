package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"time"
)

// 生成自签名证书：cert.pem 和 key.pem
func generateCert() error {
	// 生成私钥
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return err
	}

	// 证书模板
	template := x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject: pkix.Name{
			CommonName: "lan-server", // 自定义局域网域名
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              []string{"localhost", "lan-server"},                              // 局域网域名
		IPAddresses:           []net.IP{net.ParseIP("127.0.0.1"), net.ParseIP("192.168.1.100")}, // 服务器局域网IP
	}

	// 生成证书
	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &privKey.PublicKey, privKey)
	if err != nil {
		return err
	}

	// 写入 cert.pem
	certOut, err := os.Create("cert.pem")
	if err != nil {
		return err
	}
	defer certOut.Close()
	pem.Encode(certOut, &pem.Block{Type: "CERTIFICATE", Bytes: derBytes})

	// 写入 key.pem
	keyOut, err := os.Create("key.pem")
	if err != nil {
		return err
	}
	defer keyOut.Close()
	pem.Encode(keyOut, &pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(privKey)})

	return nil
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("✅ HTTPS 本地服务运行成功！"))
}

func main() {
	// 如果没有证书，自动生成
	if _, err := os.Stat("cert.pem"); os.IsNotExist(err) {
		log.Println("未找到证书，正在自动生成 cert.pem 和 key.pem...")
		if err := generateCert(); err != nil {
			log.Fatalf("生成证书失败: %v", err)
		}
		log.Println("证书生成完成！")
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", helloHandler)

	log.Println("🚀 启动 HTTPS 服务: https://localhost:4433")
	// Go 原生启动 HTTPS
	err := http.ListenAndServeTLS(":4433", "cert.pem", "key.pem", mux)
	if err != nil {
		log.Fatalf("HTTPS 启动失败: %v", err)
	}
}
