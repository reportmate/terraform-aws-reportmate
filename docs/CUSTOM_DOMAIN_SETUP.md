# 🌐 Custom Domain Configuration for ReportMate

This guide explains how to configure a stable custom domain for ReportMate using Azure Front Door, eliminating the need to update DNS records when Container Apps are redeployed.

## 🔧 **Infrastructure Architecture**

Instead of pointing your custom domain directly to Azure Container Apps (which have dynamic FQDNs that change with deployments), ReportMate uses **Azure Front Door** as a stable reverse proxy:

```
Your Domain (reportmate.ecuad.ca) 
    ↓ CNAME 
Azure Front Door (stable endpoint)
    ↓ Routes traffic to
Azure Container App (dynamic FQDN)
```

### **Benefits of This Approach:**

- ✅ **Stable DNS**: Your CNAME never needs to change
- ✅ **Automatic SSL**: Front Door manages SSL certificates automatically
- ✅ **Global CDN**: Content is cached worldwide for better performance
- ✅ **High Availability**: Automatic failover and load balancing
- ✅ **DDoS Protection**: Built-in protection against attacks

## 📋 **Setup Process**

### **Step 1: Enable Custom Domain in Terraform**

Your `terraform.tfvars` should already have:

```hcl
enable_custom_domain = true
custom_domain_name   = "reportmate.ecuad.ca"
```

### **Step 2: Deploy the Infrastructure**

```bash
cd infrastructure
terraform apply
```

This creates:
- Azure Front Door profile
- Custom domain configuration
- SSL certificate (automatically managed)
- Routing rules to your Container App

### **Step 3: Get Domain Validation Token**

After deployment, get the validation token:

```bash
terraform output frontdoor_validation_token
```

### **Step 4: Update DNS Records**

You need to create **two DNS records**:

#### **A. Domain Validation Record (TXT)**
```
Name: _dnsauth.reportmate.ecuad.ca
Type: TXT
Value: [frontdoor_validation_token from Step 3]
TTL: 3600
```

#### **B. Main Domain Record (CNAME)** 
```
Name: reportmate.ecuad.ca
Type: CNAME  
Value: [frontdoor_endpoint from terraform output]
TTL: 3600
```

### **Step 5: Verify Configuration**

After DNS propagation (usually 5-15 minutes), verify:

```bash
# Check domain resolution
dig reportmate.ecuad.ca

# Test HTTPS access
curl -I https://reportmate.ecuad.ca
```

## 🔄 **Current Status & Next Steps**

### **What's Already Configured:**

- ✅ Azure Front Door infrastructure deployed
- ✅ Custom domain configuration ready
- ✅ Automatic SSL certificate provisioning enabled
- ✅ Routing rules configured

### **What You Need to Do:**

1. **Get the validation token:**
   ```bash
   cd /Users/rod/DevOps/ReportMate/infrastructure
   terraform output frontdoor_validation_token
   ```

2. **Get the Front Door endpoint:**
   ```bash
   terraform output frontdoor_endpoint
   ```

3. **Update your DNS records** with the values from steps 1 and 2

4. **Wait for DNS propagation** (5-15 minutes)

5. **Verify the setup** works

## 🛠️ **Troubleshooting**

### **DNS Not Resolving**

```bash
# Check current DNS resolution
dig reportmate.ecuad.ca

# Check validation record
dig TXT _dnsauth.reportmate.ecuad.ca

# Force DNS cache refresh (macOS)
sudo dscacheutil -flushcache
```

### **SSL Certificate Issues**

- Front Door automatically provisions SSL certificates
- It may take 30-60 minutes for the certificate to be issued
- Check the Azure portal for certificate status

### **Still Seeing Old Container App URL**

This is normal during the transition. The old CNAME will continue to work until you:
1. Complete the Front Door DNS setup
2. Verify the new setup works
3. (Optional) Remove the old CNAME record

## 📊 **Monitoring**

Once configured, you can monitor traffic through:

- **Azure Front Door logs** in Azure Monitor
- **Application Insights** for application-level metrics
- **DNS monitoring** to ensure resolution is working

## 🔒 **Security Benefits**

Front Door provides additional security features:

- **Web Application Firewall (WAF)** - Optional but recommended
- **Rate limiting** - Automatic protection against abuse
- **Geo-filtering** - Block traffic from specific regions if needed
- **Custom security rules** - Fine-grained access control

## 📝 **Summary**

This setup provides a production-ready, stable domain configuration that:

1. **Never requires DNS updates** when you redeploy your application
2. **Automatically manages SSL certificates** 
3. **Provides global CDN performance**
4. **Includes enterprise security features**

Your `reportmate.ecuad.ca` domain will remain stable regardless of Container App redeployments, solving the original CNAME update problem permanently.
