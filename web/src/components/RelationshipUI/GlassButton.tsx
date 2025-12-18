import { motion } from 'framer-motion';
import { ReactNode } from 'react';
import { cn } from '@/lib/utils';

interface GlassButtonProps {
  children: ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'success' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  disabled?: boolean;
}

const variants = {
  primary: 'romantic-gradient text-foreground glow-effect hover:brightness-110',
  success: 'bg-success/80 text-success-foreground hover:bg-success/90',
  danger: 'bg-destructive/80 text-destructive-foreground hover:bg-destructive/90',
  ghost: 'bg-foreground/10 text-foreground hover:bg-foreground/20 border border-foreground/20',
};

const sizes = {
  sm: 'px-4 py-2 text-sm',
  md: 'px-6 py-3 text-base',
  lg: 'px-8 py-4 text-lg',
};

export function GlassButton({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  className,
  disabled = false,
}: GlassButtonProps) {
  return (
    <motion.button
      whileHover={{ scale: disabled ? 1 : 1.05 }}
      whileTap={{ scale: disabled ? 1 : 0.95 }}
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'rounded-2xl font-semibold transition-all duration-300',
        'backdrop-blur-sm shadow-lg',
        'flex items-center justify-center gap-2',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        variants[variant],
        sizes[size],
        className
      )}
    >
      {children}
    </motion.button>
  );
}
