import { useState } from 'react';
import { RelationshipUI } from '@/components/RelationshipUI';
import { motion } from 'framer-motion';
import { Heart } from 'lucide-react';

const Index = () => {
  const [isOpen, setIsOpen] = useState(true);

  return (
    <div className="min-h-screen bg-transparent">
      {/* Demo toggle button - In FiveM this would be triggered by game events */}
      {!isOpen && (
        <motion.button
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => setIsOpen(true)}
          className="fixed bottom-6 right-6 w-14 h-14 rounded-full romantic-gradient glow-effect
                   flex items-center justify-center text-foreground shadow-xl"
        >
          <Heart className="w-7 h-7 fill-current" />
        </motion.button>
      )}

      {/* Relationship UI */}
      {isOpen && <RelationshipUI onClose={() => setIsOpen(false)} />}
    </div>
  );
};

export default Index;
