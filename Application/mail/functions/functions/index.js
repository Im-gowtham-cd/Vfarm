const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const sgMail = require("@sendgrid/mail");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();


sgMail.setApiKey("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");

// Utility Functions
const formatDate = (dateString) => {
  if (!dateString) return "Not available";
  try {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (error) {
    console.error("Date formatting error:", error);
    return "Invalid date";
  }
};

const formatFarmLocation = (location) => {
  return location || "Not specified";
};

const formatCropTypes = (crops) => {
  if (!crops) return "Not specified";
  if (Array.isArray(crops)) return crops.join(", ");
  return crops.split(", ").join(", ");
};

const getCurrentStep = (steps) => {
  if (!Array.isArray(steps)) return "Application Processing";
  const currentStep = steps.find(step => step.isCurrent);
  return currentStep ? currentStep.title : "Application Processing";
};

const getApplicationProgress = (steps) => {
  if (!Array.isArray(steps)) return { completed: 0, total: 0, percentage: 0 };
  const completed = steps.filter(step => step.isCompleted).length;
  const total = steps.length;
  const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;
  return { completed, total, percentage };
};

// Enhanced Email Templates
const createApplicationConfirmationEmail = (data, appData, applicationId, schemeName, userName, recipientEmail) => {
  const progress = getApplicationProgress(data?.steps);
  
  return {
    to: recipientEmail,
    from: {
      email: "vfarmtech.in@gmail.com",
      name: "VFarm Support",
    },
    subject: `✅ Application Confirmed - ${schemeName} | Ref: ${applicationId?.slice(-8).toUpperCase()}`,
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
        <div style="background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
          
          <!-- Header -->
          <div style="text-align: center; margin-bottom: 30px;">
            <div style="background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 25px; border-radius: 12px; margin-bottom: 20px;">
              <h1 style="margin: 0; font-size: 26px; font-weight: 700;">✅ Application Successfully Submitted!</h1>
              <p style="margin: 10px 0 0 0; opacity: 0.9; font-size: 16px;">Your journey towards agricultural support begins now</p>
            </div>
          </div>

          <!-- Greeting -->
          <div style="margin-bottom: 25px;">
            <h2 style="color: #2c3e50; margin: 0 0 15px 0; font-size: 20px;">Dear ${userName},</h2>
            <p style="color: #34495e; line-height: 1.6; margin: 0; font-size: 16px;">
              Thank you for applying to the <strong style="color: #4CAF50;">${schemeName}</strong> scheme through VFarm. Your application has been successfully received and is now being processed by our dedicated team.
            </p>
          </div>

          <!-- Application Summary -->
          <div style="background: linear-gradient(135deg, #f1f8e9, #e8f5e8); border-left: 5px solid #4CAF50; padding: 25px; margin: 25px 0; border-radius: 0 12px 12px 0;">
            <h3 style="color: #2e7d32; margin: 0 0 20px 0; font-size: 20px; display: flex; align-items: center;">
              📋 Application Summary
            </h3>
            <div style="background-color: white; padding: 20px; border-radius: 8px;">
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600; width: 40%;">Application ID:</td>
                  <td style="padding: 12px 0; color: #333; font-family: 'Courier New', monospace; background-color: #f8f9fa; padding: 8px 12px; border-radius: 4px; font-weight: bold;">${applicationId?.slice(-8).toUpperCase() || 'N/A'}</td>
                </tr>
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600;">Submitted On:</td>
                  <td style="padding: 12px 0; color: #333;">${formatDate(appData?.submittedAt || new Date().toISOString())}</td>
                </tr>
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600;">Farm Location:</td>
                  <td style="padding: 12px 0; color: #333;">${formatFarmLocation(appData?.farmLocation)}</td>
                </tr>
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600;">Farm Size:</td>
                  <td style="padding: 12px 0; color: #333;">${appData?.farmSize ? appData.farmSize + ' acres' : 'Not specified'}</td>
                </tr>
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600;">Crop Types:</td>
                  <td style="padding: 12px 0; color: #333;">${formatCropTypes(appData?.cropTypes)}</td>
                </tr>
                <tr>
                  <td style="padding: 12px 0; color: #555; font-weight: 600;">Contact Phone:</td>
                  <td style="padding: 12px 0; color: #333;">${appData?.phone || 'Not provided'}</td>
                </tr>
              </table>
            </div>
          </div>

          <!-- Progress Tracker -->
          <div style="background: linear-gradient(135deg, #e3f2fd, #bbdefb); border-left: 5px solid #2196F3; padding: 25px; margin: 25px 0; border-radius: 0 12px 12px 0;">
            <h3 style="color: #1976d2; margin: 0 0 15px 0; font-size: 18px;">🔄 Application Progress</h3>
            <div style="background-color: white; padding: 20px; border-radius: 8px;">
              <div style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                <span style="color: #333; font-weight: 600;">Current Status: ${getCurrentStep(data?.steps)}</span>
                <span style="color: #1976d2; font-weight: 700;">${progress.completed}/${progress.total} Steps</span>
              </div>
              <div style="background-color: #f5f5f5; height: 12px; border-radius: 6px; overflow: hidden; margin-bottom: 10px;">
                <div style="background: linear-gradient(90deg, #4CAF50, #45a049); height: 100%; width: ${progress.percentage}%; transition: width 0.3s ease;"></div>
              </div>
              <p style="margin: 0; color: #666; font-size: 14px; text-align: center;">
                ${progress.percentage}% Complete • Processing typically takes 7-14 business days
              </p>
            </div>
          </div>

          <!-- Next Steps -->
          <div style="margin: 30px 0;">
            <h3 style="color: #2c3e50; margin-bottom: 20px; font-size: 20px;">📋 What Happens Next?</h3>
            <div style="background: linear-gradient(135deg, #fafafa, #f0f0f0); padding: 25px; border-radius: 12px;">
              <div style="display: grid; gap: 15px;">
                <div style="display: flex; align-items: flex-start; padding: 15px; background-color: white; border-radius: 8px; border-left: 4px solid #4CAF50;">
                  <span style="background-color: #4CAF50; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 15px; flex-shrink: 0;">1</span>
                  <div>
                    <strong style="color: #2c3e50;">Document Verification</strong>
                    <p style="margin: 5px 0 0 0; color: #666; line-height: 1.5;">Our verification team will thoroughly review all submitted documents and credentials</p>
                  </div>
                </div>
                <div style="display: flex; align-items: flex-start; padding: 15px; background-color: white; border-radius: 8px; border-left: 4px solid #ff9800;">
                  <span style="background-color: #ff9800; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 15px; flex-shrink: 0;">2</span>
                  <div>
                    <strong style="color: #2c3e50;">Eligibility Assessment</strong>
                    <p style="margin: 5px 0 0 0; color: #666; line-height: 1.5;">We'll validate your application against all scheme criteria and requirements</p>
                  </div>
                </div>
                <div style="display: flex; align-items: flex-start; padding: 15px; background-color: white; border-radius: 8px; border-left: 4px solid #2196f3;">
                  <span style="background-color: #2196f3; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 15px; flex-shrink: 0;">3</span>
                  <div>
                    <strong style="color: #2c3e50;">Final Approval & Disbursement</strong>
                    <p style="margin: 5px 0 0 0; color: #666; line-height: 1.5;">Upon successful verification, scheme benefits will be processed and disbursed</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Important Notes -->
          <div style="background: linear-gradient(135deg, #fff3cd, #ffeaa7); border-left: 5px solid #ffc107; padding: 25px; margin: 25px 0; border-radius: 0 12px 12px 0;">
            <h4 style="color: #856404; margin: 0 0 15px 0; font-size: 18px;">⚠️ Important Information</h4>
            <div style="background-color: white; padding: 20px; border-radius: 8px;">
              <ul style="color: #856404; margin: 0; padding-left: 20px; line-height: 1.8;">
                <li><strong>Reference ID:</strong> Always quote <code style="background-color: #f8f9fa; padding: 2px 6px; border-radius: 3px;">${applicationId?.slice(-8).toUpperCase()}</code> in all communications</li>
                <li><strong>Processing Time:</strong> Standard processing takes 7-14 business days from submission</li>
                <li><strong>Contact Details:</strong> Keep your phone number (${appData?.phone}) active for SMS updates</li>
                <li><strong>Document Requests:</strong> Submit any additional documents within 48 hours if requested</li>
                <li><strong>Status Updates:</strong> You'll receive email and SMS notifications at each milestone</li>
              </ul>
            </div>
          </div>

          <!-- Contact Support -->
          <div style="text-align: center; margin: 30px 0; padding: 30px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px;">
            <h4 style="color: #2c3e50; margin-bottom: 15px; font-size: 20px;">Need Assistance? We're Here to Help!</h4>
            <p style="color: #666; margin-bottom: 20px; font-size: 16px;">
              Our dedicated support team is available to assist you with any questions or concerns
            </p>
            <div style="margin: 20px 0;">
              <a href="mailto:vfarmtech.in@gmail.com" style="display: inline-block; background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 8px; transition: all 0.3s ease; box-shadow: 0 2px 10px rgba(76,175,80,0.3);">
                📧 Email Support
              </a>
              <a href="tel:+91${appData?.phone?.replace(/\D/g, '') || '9342696026'}" style="display: inline-block; background: linear-gradient(135deg, #2196F3, #1976d2); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 8px; transition: all 0.3s ease; box-shadow: 0 2px 10px rgba(33,150,243,0.3);">
                📞 Call Support
              </a>
            </div>
          </div>

          <!-- Footer -->
          <div style="text-align: center; margin-top: 40px; padding-top: 25px; border-top: 3px solid #4CAF50;">
            <div style="margin-bottom: 20px;">
              <h3 style="color: #4CAF50; font-weight: 700; font-size: 22px; margin: 0;">
                Thank you for choosing VFarm! 🌱
              </h3>
              <p style="color: #666; margin: 8px 0; font-style: italic;">
                Empowering Farmers, Growing Futures, Building Sustainable Communities
              </p>
            </div>
            
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px;">
              <p style="color: #666; margin: 0; font-size: 14px;">
                <strong>VFarm Agricultural Solutions</strong><br>
                Transforming Agriculture Through Technology
              </p>
            </div>
            
            <p style="color: #999; font-size: 12px; margin-top: 20px; line-height: 1.5;">
              This is an automated confirmation email. Please do not reply directly.<br>
              For support and inquiries: <a href="mailto:vfarmtech.in@gmail.com" style="color: #4CAF50; text-decoration: none;">vfarmtech.in@gmail.com</a><br>
              <span style="font-size: 11px;">© ${new Date().getFullYear()} VFarm. All rights reserved.</span>
            </p>
          </div>
        </div>
      </div>
    `
  };
};

const createStepCompletionEmail = (recipientEmail, schemeName, completedStep, allSteps, applicationId) => {
  const progress = getApplicationProgress(allSteps);
  const nextStep = allSteps.find(step => step.isCurrent);
  
  return {
    to: recipientEmail,
    from: {
      email: "vfarmtech.in@gmail.com",
      name: "VFarm Support",
    },
    subject: `🎉 Progress Update: ${completedStep.title} Completed | ${schemeName}`,
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
        <div style="background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
          
          <!-- Header -->
          <div style="text-align: center; margin-bottom: 25px;">
            <div style="background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 20px; border-radius: 12px;">
              <h1 style="margin: 0; font-size: 24px; font-weight: 700;">🎉 Great Progress!</h1>
              <p style="margin: 8px 0 0 0; opacity: 0.9;">Your application is moving forward</p>
            </div>
          </div>

          <!-- Main Content -->
          <div style="margin-bottom: 25px;">
            <h2 style="color: #2c3e50; margin: 0 0 15px 0; font-size: 18px;">Dear Applicant,</h2>
            <p style="color: #34495e; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
              Excellent news! We've successfully completed another step in your <strong style="color: #4CAF50;">${schemeName}</strong> application process.
            </p>
            
            <div style="background: linear-gradient(135deg, #e8f5e8, #f1f8e9); border-left: 5px solid #4CAF50; padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0;">
              <h3 style="color: #2e7d32; margin: 0 0 10px 0; font-size: 18px;">✅ Recently Completed</h3>
              <p style="color: #2c3e50; margin: 0; font-size: 16px; font-weight: 600;">
                ${completedStep.title}
              </p>
              <p style="color: #666; margin: 5px 0 0 0; font-size: 14px;">
                Completed on ${formatDate(new Date().toISOString())}
              </p>
            </div>
          </div>

          <!-- Progress Overview -->
          <div style="background: linear-gradient(135deg, #e3f2fd, #bbdefb); border-left: 5px solid #2196F3; padding: 20px; margin: 25px 0; border-radius: 0 8px 8px 0;">
            <h3 style="color: #1976d2; margin: 0 0 15px 0; font-size: 18px;">📊 Application Progress</h3>
            <div style="background-color: white; padding: 15px; border-radius: 6px;">
              <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                <span style="color: #333; font-weight: 600;">Overall Progress</span>
                <span style="color: #1976d2; font-weight: 700;">${progress.completed}/${progress.total} Steps Complete</span>
              </div>
              <div style="background-color: #f5f5f5; height: 10px; border-radius: 5px; overflow: hidden; margin-bottom: 8px;">
                <div style="background: linear-gradient(90deg, #4CAF50, #45a049); height: 100%; width: ${progress.percentage}%; transition: width 0.3s ease;"></div>
              </div>
              <p style="margin: 0; color: #666; font-size: 13px; text-align: center;">
                ${progress.percentage}% Complete
              </p>
            </div>
          </div>

          <!-- Next Step -->
          ${nextStep ? `
          <div style="background: linear-gradient(135deg, #fff3cd, #ffeaa7); border-left: 5px solid #ff9800; padding: 20px; margin: 25px 0; border-radius: 0 8px 8px 0;">
            <h3 style="color: #f57c00; margin: 0 0 10px 0; font-size: 18px;">🔄 Up Next</h3>
            <p style="color: #333; margin: 0; font-weight: 600;">${nextStep.title}</p>
            <p style="color: #666; margin: 5px 0 0 0; font-size: 14px;">Currently in progress</p>
          </div>
          ` : `
          <div style="background: linear-gradient(135deg, #e8f5e8, #f1f8e9); border-left: 5px solid #4CAF50; padding: 20px; margin: 25px 0; border-radius: 0 8px 8px 0;">
            <h3 style="color: #2e7d32; margin: 0 0 10px 0; font-size: 18px;">🎊 Application Complete!</h3>
            <p style="color: #333; margin: 0; font-weight: 600;">All steps have been completed successfully!</p>
          </div>
          `}

          <!-- All Steps Status -->
          <div style="margin: 25px 0;">
            <h3 style="color: #2c3e50; margin-bottom: 15px; font-size: 18px;">📋 Complete Step Breakdown</h3>
            <div style="background-color: #fafafa; padding: 20px; border-radius: 8px;">
              ${allSteps.map((step, index) => `
                <div style="display: flex; align-items: center; padding: 10px 0; border-bottom: 1px solid #eee;">
                  <span style="background-color: ${step.isCompleted ? '#4CAF50' : (step.isCurrent ? '#ff9800' : '#ccc')}; color: white; width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 15px; flex-shrink: 0;">
                    ${step.isCompleted ? '✓' : (index + 1)}
                  </span>
                  <div style="flex-grow: 1;">
                    <strong style="color: #2c3e50;">${step.title}</strong>
                    <div style="color: #666; font-size: 14px; margin-top: 2px;">
                      ${step.isCompleted ? '✅ Completed' : (step.isCurrent ? '🔄 In Progress' : '⏳ Pending')}
                    </div>
                  </div>
                </div>
              `).join('')}
            </div>
          </div>

          <!-- Contact & Footer -->
          <div style="text-align: center; margin: 25px 0; padding: 20px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 8px;">
            <p style="color: #666; margin-bottom: 15px;">
              Questions about your application? We're here to help!
            </p>
            <a href="mailto:vfarmtech.in@gmail.com" style="display: inline-block; background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px; font-weight: 600;">
              📧 Contact Support
            </a>
          </div>

          <!-- Footer -->
          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 2px solid #eee;">
            <p style="color: #4CAF50; font-weight: 600; font-size: 18px; margin-bottom: 5px;">
              Thank you for choosing VFarm! 🌱
            </p>
            <p style="color: #666; margin-bottom: 5px;">
              <strong>VFarm Team</strong><br>
              Empowering Farmers, Growing Futures
            </p>
            ${applicationId ? `
            <p style="color: #999; font-size: 12px; margin-top: 15px;">
              Application Reference: <code>${applicationId.slice(-8).toUpperCase()}</code>
            </p>
            ` : ''}
            <p style="color: #999; font-size: 12px; margin-top: 10px;">
              This is an automated update. For support: <a href="mailto:vfarmtech.in@gmail.com" style="color: #4CAF50;">vfarmtech.in@gmail.com</a>
            </p>
          </div>
        </div>
      </div>
    `
  };
};

// Function 1: Send Email on Scheme Application Creation
exports.sendEmailOnSchemeApply = onDocumentCreated("scheme_applications/{applicationId}", async (event) => {
  try {
    const data = event.data.data();
    const applicationId = event.params.applicationId;
    
    console.log("Processing new application:", applicationId);
    
    // Extract application data
    const appData = data?.applicationData || data;
    const recipientEmail = appData?.email || data?.email;
    const userName = appData?.name || data?.applicantName || "Applicant";
    const schemeName = data?.schemeName || data?.scheme_name || "Government Scheme";
    
    if (!recipientEmail) {
      console.error("No email address found in document:", applicationId);
      return;
    }

    // Create and send confirmation email
    const emailMsg = createApplicationConfirmationEmail(data, appData, applicationId, schemeName, userName, recipientEmail);
    
    await sgMail.send(emailMsg);
    console.log(`✅ Application confirmation email sent to ${recipientEmail} for application ${applicationId}`);
    
    // Log to Firestore for audit trail
    try {
      await db.collection('email_logs').add({
        type: 'application_confirmation',
        applicationId: applicationId,
        recipientEmail: recipientEmail,
        schemeName: schemeName,
        sentAt: new Date(),
        status: 'sent'
      });
    } catch (logError) {
      console.warn("Failed to log email to Firestore:", logError);
    }
    
  } catch (error) {
    console.error("Error in sendEmailOnSchemeApply:", error);
    
    // Log error to Firestore
    try {
      await db.collection('email_logs').add({
        type: 'application_confirmation',
        applicationId: event.params.applicationId,
        error: error.message,
        sentAt: new Date(),
        status: 'failed'
      });
    } catch (logError) {
      console.warn("Failed to log error to Firestore:", logError);
    }
  }
});

// Function 2: Notify on Step Completion
exports.notifyOnStepCompletion = onDocumentUpdated("scheme_applications/{applicationId}", async (event) => {
  try {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const applicationId = event.params.applicationId;

    console.log("Processing step update for application:", applicationId);

    // Validate steps data
    if (!Array.isArray(beforeData.steps) || !Array.isArray(afterData.steps)) {
      console.log("Steps array missing or invalid. Skipping notification for:", applicationId);
      return null;
    }

    // Find newly completed steps
    const completedSteps = [];
    afterData.steps.forEach((step, index) => {
      if (step.isCompleted === true && beforeData.steps[index]?.isCompleted === false) {
        completedSteps.push({ step, index });
      }
    });

    if (completedSteps.length === 0) {
      console.log("No newly completed steps found for application:", applicationId);
      return null;
    }

    // Get recipient information
    const recipientEmail = afterData.email || afterData.applicationData?.email;
    const schemeName = afterData.schemeName || afterData.scheme_name || "Your Scheme";

    if (!recipientEmail) {
      console.error("No email address found for application:", applicationId);
      return null;
    }

    // Send notification for each completed step
    for (const { step, index } of completedSteps) {
      try {
        const emailMsg = createStepCompletionEmail(
          recipientEmail,
          schemeName,
          step,
          afterData.steps,
          applicationId
        );

        await sgMail.send(emailMsg);
        console.log(`✅ Step completion email sent to ${recipientEmail} for step: ${step.title}`);

        // Log successful email
        await db.collection('email_logs').add({
          type: 'step_completion',
          applicationId: applicationId,
          recipientEmail: recipientEmail,
          stepTitle: step.title,
          stepIndex: index,
          schemeName: schemeName,
          sentAt: new Date(),
          status: 'sent'
        });

      } catch (stepError) {
        console.error(`Error sending step completion email for step "${step.title}":`, stepError);
        
        // Log error to Firestore
        await db.collection('email_logs').add({
          type: 'step_completion',
          applicationId: applicationId,
          recipientEmail: recipientEmail,
          stepTitle: step.title,
          stepIndex: index,
          error: stepError.message,
          sentAt: new Date(),
          status: 'failed'
        });
      }
    }

    return null;

  } catch (error) {
    console.error("Error in notifyOnStepCompletion:", error);
    
    // Log general error
    try {
      await db.collection('email_logs').add({
        type: 'step_completion',
        applicationId: event.params.applicationId,
        error: error.message,
        sentAt: new Date(),
        status: 'failed'
      });
    } catch (logError) {
      console.warn("Failed to log error to Firestore:", logError);
    }
    
    return null;
  }
});

// Function 3: Health Check Endpoint (Optional - for monitoring)
exports.healthCheck = require("firebase-functions").https.onRequest((req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    functions: [
      "sendEmailOnSchemeApply",
      "notifyOnStepCompletion"
    ],
    version: "2.0.0"
  });
});

// Function 4: Manual Email Trigger (Optional - for testing)
exports.sendTestEmail = require("firebase-functions").https.onCall(async (data, context) => {
  // Only allow authenticated admin users
  if (!context.auth || !context.auth.token.admin) {
    throw new require("firebase-functions").https.HttpsError(
      'permission-denied',
      'Only admin users can send test emails.'
    );
  }

  const { email, type = "test" } = data;

  if (!email) {
    throw new require("firebase-functions").https.HttpsError(
      'invalid-argument',
      'Email address is required.'
    );
  }

  try {
    const testMsg = {
      to: email,
      from: {
        email: "vfarmtech.in@gmail.com",
        name: "VFarm Support",
      },
      subject: "🧪 VFarm Email System Test",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background-color: #4CAF50; color: white; padding: 20px; border-radius: 8px; text-align: center;">
            <h1>✅ Email System Test Successful!</h1>
          </div>
          <div style="background-color: white; padding: 20px; border-radius: 8px; margin-top: 20px; border: 1px solid #ddd;">
            <p>This is a test email from the VFarm notification system.</p>
            <p><strong>Test Type:</strong> ${type}</p>
            <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
            <p><strong>System Status:</strong> Operational</p>
          </div>
          <div style="text-align: center; margin-top: 20px; color: #666;">
            <p>VFarm Email Notification System</p>
          </div>
        </div>
      `
    };

    await sgMail.send(testMsg);
    
    // Log test email
    await db.collection('email_logs').add({
      type: 'test_email',
      recipientEmail: email,
      testType: type,
      sentBy: context.auth.uid,
      sentAt: new Date(),
      status: 'sent'
    });

    return {
      success: true,
      message: `Test email sent successfully to ${email}`,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("Error sending test email:", error);
    
    // Log test email error
    try {
      await db.collection('email_logs').add({
        type: 'test_email',
        recipientEmail: email,
        testType: type,
        sentBy: context.auth.uid,
        error: error.message,
        sentAt: new Date(),
        status: 'failed'
      });
    } catch (logError) {
      console.warn("Failed to log test email error:", logError);
    }

    throw new require("firebase-functions").https.HttpsError(
      'internal',
      'Failed to send test email: ' + error.message
    );
  }
});

// Function 5: Email Analytics (Optional - for insights)
exports.getEmailAnalytics = require("firebase-functions").https.onCall(async (data, context) => {
  // Only allow authenticated admin users
  if (!context.auth || !context.auth.token.admin) {
    throw new require("firebase-functions").https.HttpsError(
      'permission-denied',
      'Only admin users can access email analytics.'
    );
  }

  try {
    const { startDate, endDate, type } = data;
    let query = db.collection('email_logs');

    // Add filters if provided
    if (startDate) {
      query = query.where('sentAt', '>=', new Date(startDate));
    }
    if (endDate) {
      query = query.where('sentAt', '<=', new Date(endDate));
    }
    if (type) {
      query = query.where('type', '==', type);
    }

    const snapshot = await query.orderBy('sentAt', 'desc').limit(1000).get();
    const logs = [];
    
    snapshot.forEach(doc => {
      logs.push({
        id: doc.id,
        ...doc.data(),
        sentAt: doc.data().sentAt?.toDate?.()?.toISOString() || doc.data().sentAt
      });
    });

    // Calculate statistics
    const stats = {
      total: logs.length,
      sent: logs.filter(log => log.status === 'sent').length,
      failed: logs.filter(log => log.status === 'failed').length,
      byType: {}
    };

    // Group by type
    logs.forEach(log => {
      if (!stats.byType[log.type]) {
        stats.byType[log.type] = { sent: 0, failed: 0, total: 0 };
      }
      stats.byType[log.type].total++;
      stats.byType[log.type][log.status]++;
    });

    return {
      success: true,
      stats,
      logs: logs.slice(0, 100), // Return latest 100 logs
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error("Error fetching email analytics:", error);
    throw new require("firebase-functions").https.HttpsError(
      'internal',
      'Failed to fetch analytics: ' + error.message
    );
  }
});

// Export configuration for easier maintenance
exports.emailConfig = {
  FROM_EMAIL: "vfarmtech.in@gmail.com",
  FROM_NAME: "VFarm Support",
  SENDGRID_API_KEY: "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",
  DEFAULT_SCHEME_NAME: "Government Scheme",
  EMAIL_TEMPLATES: {
    APPLICATION_CONFIRMATION: "application_confirmation",
    STEP_COMPLETION: "step_completion",
    TEST_EMAIL: "test_email"
  }
};
