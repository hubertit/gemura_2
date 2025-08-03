# OpenAI API Setup Instructions

## 🔑 Getting Your OpenAI API Key

1. **Visit OpenAI**: Go to [https://platform.openai.com/](https://platform.openai.com/)
2. **Sign Up/Login**: Create an account or log in
3. **Get API Key**: 
   - Go to "API Keys" section
   - Click "Create new secret key"
   - Copy your API key (starts with `sk-`)

## ⚙️ Configure the App

**Good news!** The app is already configured with an OpenAI API key in `lib/core/config/app_config.dart`. 

The document analysis feature will automatically use the same API key as the bot. No additional configuration needed!

If you need to update the API key:
1. **Open the config file**: `lib/core/config/app_config.dart`
2. **Update the existing key**: 
   ```dart
   static const String chatGptApiKey = 'sk-your-actual-api-key-here';
   ```

## 💰 Pricing Information

- **GPT-3.5 Turbo**: ~$0.002 per 1K tokens (very affordable)
- **Typical receipt analysis**: ~500-1000 tokens (~$0.001-0.002 per receipt)
- **Free tier**: $5 credit for new users

## 🚀 Features Enabled

With OpenAI API configured, the bot can:

### 📄 **Smart Document Analysis**
- **Contact Processing**: Extract and analyze contact information
- **Document Classification**: Identify document types automatically
- **Business Context**: Understand dairy business relevance
- **Structured Data**: Extract contact details and business information

### 🧠 **AI-Powered Insights**
- **Business Context**: Understand dairy business relevance
- **Actionable Recommendations**: Suggest next steps for farmers
- **Financial Categorization**: Help with expense tracking
- **Compliance Guidance**: Tax and regulatory implications

### 📊 **Structured Data Extraction**
- **Contact Information**: Names, phones, emails, addresses
- **Business Details**: Company names, addresses, contact info
- **Document Metadata**: File types, sizes, formats
- **Business Context**: Dairy business relevance and insights

## 🔒 Security Notes

- **Never commit API keys** to version control
- **Use environment variables** in production
- **Monitor usage** in OpenAI dashboard
- **Set spending limits** to control costs

## 🧪 Testing

1. **Run the app**: `flutter run`
2. **Go to Chats tab**
3. **Open Karake chat**
4. **Share a receipt or document image**
5. **See AI analysis** with extracted data and insights

## 🆘 Troubleshooting

### API Key Issues
- **Invalid API key**: Check the key format (starts with `sk-`)
- **Rate limiting**: Wait a moment and try again
- **Network issues**: Check internet connection

### OCR Issues
- **No text found**: Image might not have clear text
- **Poor quality**: Try better lighting or focus
- **Handwriting**: Works best with printed text

## 💡 Tips for Best Results

1. **Clear Images**: Good lighting and focus
2. **Printed Text**: Works better than handwriting
3. **Complete Documents**: Show full receipt/document
4. **High Resolution**: Better quality = better extraction

## 🔄 Fallback System

If OpenAI API fails:
- **Basic OCR**: Still extracts text using Google ML Kit
- **Simple Analysis**: Provides basic document classification
- **Error Handling**: Graceful degradation with helpful messages 