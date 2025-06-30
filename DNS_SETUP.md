# DNS Setup for Custom Domain

## Required DNS Records

To enable the custom domain `reportmate.ecuad.ca` with Azure Front Door, you need to configure the following DNS records:

### 1. CNAME Record (Primary Domain)
```
Record Type: CNAME
Name: reportmate
Value: reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net
TTL: 300 (5 minutes)
```

### 2. TXT Record (Domain Validation)
```
Record Type: TXT
Name: _dnsauth.reportmate
Value: _ene3huqnlopx2s5yfauesy9o4upxg49
TTL: 300 (5 minutes)
```

## What These Records Do

- **CNAME Record**: Routes traffic from `reportmate.ecuad.ca` to the Azure Front Door endpoint
- **TXT Record**: Validates domain ownership so Azure can issue the managed TLS certificate

## Timeline

1. **DNS Propagation**: 5-15 minutes after adding records
2. **Certificate Issuance**: ~45 minutes after TXT record propagates
3. **Full Activation**: The custom domain will be fully active once the certificate is issued

## Verification Commands

After adding the DNS records, you can verify the setup:

```bash
# Check CNAME record
dig reportmate.ecuad.ca CNAME

# Check TXT record for validation
dig _dnsauth.reportmate.ecuad.ca TXT

# Test the endpoints (after applying Terraform changes)
curl -I https://reportmate-frontend-bxabcae2dpgdhmcz.z02.azurefd.net   # expect 200
curl -I https://reportmate.ecuad.ca                                   # expect 200 once TLS is active
```

## Next Steps

1. Add the DNS records above to your DNS provider
2. Run `terraform apply -auto-approve` to deploy the Front Door configuration
3. Wait for certificate issuance (~45 minutes)
4. Test both the Front Door endpoint and custom domain

## Troubleshooting

If the custom domain doesn't work:
- Verify DNS records with `dig` commands above
- Check Azure Portal > Front Door > Custom Domain status
- Ensure health probe shows "Healthy" status
- Wait for certificate provisioning to complete
