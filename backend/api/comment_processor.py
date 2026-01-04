import logging
import random

logger = logging.getLogger(__name__)

class CommentProcessor:
    _instance = None
    
    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def __init__(self):
        # Initialize LLM client here (OpenAI, Claude, or Local LLM)
        pass

    def generate_reply(self, comment, viewer_name):
        """
        Generate a text reply to a viewer's comment.
        """
        logger.info(f"Generating reply for {viewer_name}: {comment}")
        
        # MOCK LOGIC for PoC
        # In production, replace with LLM call
        
        greetings = [
            f"Chào {viewer_name}, cảm ơn bạn đã comment nhé!",
            f"Hello {viewer_name}, câu hỏi rất hay!",
            f"Ui {viewer_name} ơi, mình cũng nghĩ vậy đó.",
            f"Cảm ơn {viewer_name} đã ủng hộ livestream nha!"
        ]
        
        # Simple keywords
        if "hát" in comment.lower():
            return f"{viewer_name} muốn mình hát bài gì nào? Comment tên bài hát nhé!"
        elif "đẹp" in comment.lower():
            return f"Cảm ơn {viewer_name} khen mình nha, ngại quá hihi."
        elif "tên gì" in comment.lower():
            return f"Mình là Idol AI, rất vui được làm quen với {viewer_name}!"
            
        return random.choice(greetings) + f" Bạn vừa nói: {comment}"
