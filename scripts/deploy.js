#!/usr/bin/env node

/**
 * Deployment script for casey.click static website
 * Uploads built files to S3 and invalidates CloudFront cache
 */

import { execSync } from 'child_process';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Get current directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '..');

// Configuration from Terraform outputs
const CONFIG = {
  bucketName: 'casey-click-website-prod',
  distributionId: 'E20H6JIYEH8AXW',
  region: 'ap-southeast-1',
  buildDir: join(projectRoot, 'static-fe', 'dist'),
  domain: 'www.casey.click'
};

// ANSI color codes for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logStep(step, message) {
  log(`\n📋 Step ${step}: ${message}`, 'cyan');
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function execCommand(command, options = {}) {
  try {
    const result = execSync(command, {
      encoding: 'utf8',
      stdio: options.silent ? 'pipe' : 'inherit',
      ...options
    });
    return result;
  } catch (error) {
    logError(`Command failed: ${command}`);
    logError(error.message);
    process.exit(1);
  }
}

function checkPrerequisites() {
  logStep(1, 'Checking prerequisites');
  
  // Check if AWS CLI is installed
  try {
    execCommand('aws --version', { silent: true });
    logSuccess('AWS CLI is installed');
  } catch {
    logError('AWS CLI is not installed. Please install it first.');
    logError('Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html');
    process.exit(1);
  }
  
  // Check if AWS credentials are configured
  try {
    execCommand('aws sts get-caller-identity', { silent: true });
    logSuccess('AWS credentials are configured');
  } catch {
    logError('AWS credentials are not configured. Run: aws configure');
    process.exit(1);
  }
  
  // Check if build directory exists
  try {
    const buildStats = execCommand(`ls -la "${CONFIG.buildDir}"`, { silent: true });
    if (buildStats.includes('index.html')) {
      logSuccess('Build directory exists and contains index.html');
    } else {
      logWarning('Build directory exists but may be incomplete');
    }
  } catch {
    logError(`Build directory not found: ${CONFIG.buildDir}`);
    logError('Run "npm run build" first in the static-fe directory');
    process.exit(1);
  }
}

function syncToS3(dryRun = false) {
  const dryRunFlag = dryRun ? '--dryrun' : '';
  const step = dryRun ? '2 (DRY RUN)' : '2';
  
  logStep(step, `Syncing files to S3 bucket: ${CONFIG.bucketName}`);
  
  const syncCommand = `aws s3 sync "${CONFIG.buildDir}" s3://${CONFIG.bucketName}/ --delete --region ${CONFIG.region} ${dryRunFlag}`;
  
  log(`\nRunning: ${syncCommand}`, 'blue');
  
  const result = execCommand(syncCommand);
  
  if (dryRun) {
    logSuccess('Dry run completed - no files were actually uploaded');
  } else {
    logSuccess('Files successfully synced to S3');
  }
  
  return result;
}

function invalidateCloudFront(dryRun = false) {
  if (dryRun) {
    logStep('3 (DRY RUN)', 'Would invalidate CloudFront cache');
    log(`Command: aws cloudfront create-invalidation --distribution-id ${CONFIG.distributionId} --paths "/*"`, 'blue');
    logSuccess('Dry run - CloudFront invalidation skipped');
    return;
  }
  
  logStep(3, 'Invalidating CloudFront cache');
  
  const invalidateCommand = `aws cloudfront create-invalidation --distribution-id ${CONFIG.distributionId} --paths "/*"`;
  
  log(`\nRunning: ${invalidateCommand}`, 'blue');
  
  const result = execCommand(invalidateCommand);
  
  logSuccess('CloudFront cache invalidation initiated');
  log('Note: Cache invalidation can take 10-15 minutes to complete', 'yellow');
  
  return result;
}

function showDeploymentInfo(dryRun = false) {
  const step = dryRun ? '4 (DRY RUN)' : '4';
  logStep(step, 'Deployment Information');
  
  log('\n🌐 Website URLs:', 'bright');
  log(`   Primary: https://${CONFIG.domain}`, 'cyan');
  log(`   Redirect: https://casey.click → https://${CONFIG.domain}`, 'cyan');
  log(`   CloudFront: https://d1sk918hgzx1la.cloudfront.net`, 'cyan');
  
  log('\n📊 AWS Resources:', 'bright');
  log(`   S3 Bucket: ${CONFIG.bucketName}`, 'cyan');
  log(`   CloudFront Distribution: ${CONFIG.distributionId}`, 'cyan');
  log(`   Region: ${CONFIG.region}`, 'cyan');
  
  if (!dryRun) {
    log('\n⏰ Next Steps:', 'bright');
    log('   1. Wait 10-15 minutes for CloudFront cache invalidation', 'yellow');
    log('   2. Check your website at the URLs above', 'yellow');
    log('   3. DNS propagation may take up to 48 hours for custom domains', 'yellow');
  }
  
  log('\n🔧 Useful Commands:', 'bright');
  log('   Check deployment: npm run deploy:dry-run', 'cyan');
  log('   Deploy again: npm run deploy', 'cyan');
  log('   AWS S3 Console: https://s3.console.aws.amazon.com/s3/buckets/casey-click-website-prod', 'cyan');
  log('   CloudFront Console: https://console.aws.amazon.com/cloudfront/v3/home#/distributions/E20H6JIYEH8AXW', 'cyan');
}

function main() {
  const isDryRun = process.argv.includes('--dry-run');
  
  log('🚀 Casey.click Deployment Script', 'bright');
  log('=====================================', 'bright');
  
  if (isDryRun) {
    log('🧪 DRY RUN MODE - No changes will be made', 'yellow');
  }
  
  try {
    checkPrerequisites();
    syncToS3(isDryRun);
    invalidateCloudFront(isDryRun);
    showDeploymentInfo(isDryRun);
    
    if (isDryRun) {
      log('\n🧪 Dry run completed successfully!', 'green');
    } else {
      log('\n🎉 Deployment completed successfully!', 'green');
    }
  } catch (error) {
    logError(`\nDeployment failed: ${error.message}`);
    process.exit(1);
  }
}

// Run the script
main();
