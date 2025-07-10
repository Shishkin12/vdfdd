import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Search,
  Code,
  Figma,
  Palette,
  Zap,
  Check,
  Star,
  ArrowRight,
  Play,
  Users,
  Globe,
  Smartphone,
  Plus,
  Rocket,
} from "lucide-react";

export default function Index() {
  return (
    <div className="min-h-screen bg-black text-white overflow-x-hidden">
      {/* Exact Builder.io Header */}
      <header className="relative z-50 bg-black">
        <div className="max-w-none mx-auto px-6">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-8">
              <div className="flex items-center space-x-2">
                <div className="w-6 h-6 bg-gradient-to-r from-blue-400 to-purple-500 rounded-sm flex items-center justify-center">
                  <span className="text-white font-bold text-xs">◆</span>
                </div>
                <span className="text-lg font-medium text-white">
                  builder.io
                </span>
              </div>
              <nav className="hidden md:flex space-x-8">
                <div className="relative group">
                  <button className="text-gray-300 hover:text-white transition-colors text-sm font-medium">
                    Platform
                  </button>
                </div>
                <div className="relative group">
                  <button className="text-gray-300 hover:text-white transition-colors text-sm font-medium">
                    Resources
                  </button>
                </div>
                <a
                  href="#"
                  className="text-gray-300 hover:text-white transition-colors text-sm font-medium"
                >
                  Docs
                </a>
                <a
                  href="#"
                  className="text-gray-300 hover:text-white transition-colors text-sm font-medium"
                >
                  Pricing
                </a>
              </nav>
            </div>
            <div className="flex items-center space-x-3">
              <span className="text-xs text-gray-400">
                Livestream: implement features in your webapp with AI →
              </span>
              <Button
                variant="ghost"
                size="sm"
                className="text-gray-300 hover:text-white text-sm px-4 py-1"
              >
                Contact sales
              </Button>
              <Button
                size="sm"
                className="bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white text-sm px-4 py-1 rounded-md font-medium"
              >
                Get started
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Exact Hero Section */}
      <section className="relative pt-24 pb-16 px-6">
        <div className="max-w-4xl mx-auto text-center">
          {/* INTRODUCING FUSION BETA Badge */}
          <div className="inline-flex items-center bg-gray-800/60 border border-gray-700 rounded-full px-4 py-1.5 mb-8">
            <span className="text-xs font-medium text-blue-400 uppercase tracking-wider">
              INTRODUCING FUSION
            </span>
            <Badge className="ml-2 bg-purple-600 text-white text-xs px-2 py-0.5 rounded-md">
              BETA
            </Badge>
          </div>

          {/* Main Headline */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold mb-6 leading-tight">
            <span className="bg-gradient-to-b from-white to-gray-400 bg-clip-text text-transparent">
              What should we build?
            </span>
          </h1>

          <p className="text-lg text-gray-400 mb-12 font-normal">
            Using your existing design & code context
          </p>

          {/* Search Interface with exact styling */}
          <div
            className="relative bg-gradient-to-br from-purple-900/30 via-purple-800/20 to-pink-900/30 backdrop-blur-xl border border-purple-500/30 rounded-2xl p-8 mb-16"
            style={{
              background: `
                radial-gradient(circle at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 80% 20%, rgba(255, 0, 150, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 40% 40%, rgba(0, 150, 255, 0.2) 0%, transparent 50%)
              `,
            }}
          >
            {/* Search Input */}
            <div className="relative mb-6">
              <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 to-blue-500/20 rounded-xl blur-sm"></div>
              <div className="relative bg-gray-900/80 border border-gray-700/50 rounded-xl p-4 flex items-center">
                <Input
                  placeholder="Ask Fusion to build a next landing page!"
                  className="bg-transparent border-0 text-white placeholder-gray-400 text-base flex-1 focus:ring-0 focus:outline-none"
                />
                <Button
                  size="sm"
                  className="bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white ml-3 px-4 py-2 rounded-lg"
                >
                  Create
                </Button>
                <Button
                  size="sm"
                  className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white ml-3 px-4 py-2 rounded-lg"
                  onClick={() => {
                    try {
                      // @ts-ignore
                      if (
                        typeof window !== "undefined" &&
                        window.startDownload
                      ) {
                        console.log("Button clicked, calling startDownload");
                        // @ts-ignore
                        window.startDownload();
                      } else {
                        console.error("startDownload function not found");
                        alert(
                          "Функция загрузки не найдена. Перезагрузите страницу.",
                        );
                      }
                    } catch (error) {
                      console.error("Error calling startDownload:", error);
                      alert("Ошибка при запуске приложения: " + error.message);
                    }
                  }}
                >
                  <Rocket className="h-4 w-4 mr-1" />
                  ���� Запустить приложение
                </Button>
              </div>
            </div>

            {/* Suggestion Tags */}
            <div className="flex flex-wrap gap-2 justify-center">
              <Button
                variant="outline"
                size="sm"
                className="bg-gray-800/60 border-gray-600 text-gray-200 hover:bg-gray-700/60 rounded-full px-3 py-1.5 text-sm"
              >
                <Code className="h-3 w-3 mr-1.5" />
                Component library
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="bg-gray-800/60 border-gray-600 text-gray-200 hover:bg-gray-700/60 rounded-full px-3 py-1.5 text-sm"
              >
                <Figma className="h-3 w-3 mr-1.5" />
                Figma Import
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="bg-gray-800/60 border-gray-600 text-gray-200 hover:bg-gray-700/60 rounded-full px-3 py-1.5 text-sm"
              >
                <Palette className="h-3 w-3 mr-1.5" />
                API Library
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="bg-gray-800/60 border-gray-600 text-gray-200 hover:bg-gray-700/60 rounded-full px-3 py-1.5 text-sm"
              >
                <Zap className="h-3 w-3 mr-1.5" />
                Git Extension
              </Button>
            </div>
          </div>

          {/* Company Logos - exact placement */}
          <div className="flex flex-wrap items-center justify-start gap-8 opacity-40 max-w-4xl mx-auto pl-4">
            <div className="text-lg font-normal text-gray-600">zapier</div>
            <div className="text-lg font-normal text-gray-600">J.CREW</div>
            <div className="text-lg font-normal text-gray-600">HARRY'S</div>
            <div className="text-lg font-normal text-gray-600 flex items-center">
              <span className="w-4 h-4 bg-blue-500 rounded-full mr-1"></span>
              atomic
            </div>
            <div className="text-lg font-normal text-gray-600">FAIRE</div>
            <div className="text-lg font-normal text-gray-600">webflow</div>
            <div className="text-lg font-normal text-gray-600">algolia</div>
            <div className="text-lg font-normal text-gray-600">afterpay</div>
          </div>
        </div>
      </section>

      {/* VISUAL DEVELOPMENT PLATFORM Section */}
      <section className="py-24 px-6 bg-black">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center bg-blue-900/30 border border-blue-700/50 rounded-full px-4 py-1.5 mb-6">
              <span className="text-xs font-medium text-blue-400 uppercase tracking-wider">
                VISUAL DEVELOPMENT PLATFORM
              </span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold mb-6 leading-tight text-white">
              Bring the power of development to your entire team
            </h2>
            <p className="text-lg text-gray-400 max-w-3xl mx-auto leading-relaxed">
              Let both developers and non-developers leverage your existing tech
              investments to iterate and ship faster
            </p>
            <div className="absolute top-0 right-8 text-xs text-gray-500">
              Accelerate Windows
            </div>
          </div>

          {/* Feature Section 1 - Exact layout */}
          <div className="grid lg:grid-cols-2 gap-12 items-center mb-32">
            <div className="relative">
              <img
                src={`https://cdn.builder.io/api/v1/image/assets%2Fc80dc6ae7f1641aeb2c2dc3bb05cfc73%2F5a68721ca92746fa894230f43f06c22c?format=webp&width=800`}
                alt="Development interface"
                className="rounded-2xl shadow-2xl w-full"
              />
            </div>
            <div className="space-y-6">
              <h3 className="text-3xl font-bold text-white">
                Use your existing code
              </h3>
              <ul className="space-y-4">
                <li className="flex items-start space-x-3">
                  <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                    <Check className="h-3 w-3 text-white" />
                  </div>
                  <span className="text-gray-300 text-base">
                    Connect to any code repository
                  </span>
                </li>
                <li className="flex items-start space-x-3">
                  <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                    <Check className="h-3 w-3 text-white" />
                  </div>
                  <span className="text-gray-300 text-base">
                    Leverage your design systems, components, and APIs
                  </span>
                </li>
                <li className="flex items-start space-x-3">
                  <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                    <Check className="h-3 w-3 text-white" />
                  </div>
                  <span className="text-gray-300 text-base">
                    Generated code uses your components and matches your coding
                    standards
                  </span>
                </li>
              </ul>
            </div>
          </div>

          {/* Feature Section 2 - Reversed layout */}
          <div className="mb-32">
            <div className="text-center mb-8">
              <div className="inline-flex items-center bg-blue-900/30 border border-blue-700/50 rounded-full px-4 py-1.5 mb-4">
                <span className="text-xs font-medium text-blue-400 uppercase tracking-wider">
                  VISUAL DEVELOPMENT PLATFORM
                </span>
              </div>
              <h3 className="text-4xl font-bold text-white mb-4">
                Bring the power of development to your entire team
              </h3>
              <p className="text-lg text-gray-400 max-w-3xl mx-auto">
                Let both developers and non-developers leverage your existing
                tech investments to iterate and ship faster
              </p>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 items-center">
              <div className="lg:order-2 relative">
                <img
                  src={`https://cdn.builder.io/api/v1/image/assets%2Fc80dc6ae7f1641aeb2c2dc3bb05cfc73%2F2cc9ed950d6140ecb0aeafeb6774bf7d?format=webp&width=800`}
                  alt="Analytics dashboard"
                  className="rounded-2xl shadow-2xl w-full"
                />
              </div>
              <div className="lg:order-1 space-y-6">
                <h3 className="text-3xl font-bold text-white">
                  Use your existing code
                </h3>
                <ul className="space-y-4">
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Connect to any code repository
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Leverage your design systems, components, and APIs
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Generated code uses your components and matches your
                      coding standards
                    </span>
                  </li>
                </ul>
              </div>
            </div>

            {/* Bottom testimonial cards */}
            <div className="mt-16 flex justify-center space-x-8">
              <div className="bg-white rounded-lg p-4 max-w-xs">
                <p className="text-gray-800 text-sm mb-2">
                  "Hub is incredible. My fleet is safe!"
                </p>
                <div className="flex items-center space-x-2">
                  <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-xs">M</span>
                  </div>
                  <div>
                    <div className="text-gray-800 font-semibold text-sm">
                      Matt Abrams
                    </div>
                    <div className="text-gray-600 text-xs">
                      Lead Engineer, Pelican Systems
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg p-4 max-w-xs">
                <p className="text-gray-800 text-sm mb-2">
                  "Best investment for my ocean assets"
                </p>
                <div className="flex items-center space-x-2">
                  <div className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-xs">S</span>
                  </div>
                  <div>
                    <div className="text-gray-800 font-semibold text-sm">
                      Shyam Shalu Shrestha
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Figma Section with exact layout */}
          <div className="mb-32">
            <div className="grid lg:grid-cols-2 gap-12 items-start">
              <div className="space-y-6">
                <h3 className="text-3xl font-bold text-white">
                  Bring in your Figma designs
                </h3>
                <ul className="space-y-4">
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Copy/paste any Figma design
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Generated code leverages your tokens and components
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Prompt with your backend context to make designs
                      interactive
                    </span>
                  </li>
                </ul>
              </div>

              <div className="relative">
                <img
                  src={`https://cdn.builder.io/api/v1/image/assets%2Fc80dc6ae7f1641aeb2c2dc3bb05cfc73%2Fb01e472172e143819a20d8301a81e375?format=webp&width=800`}
                  alt="Figma integration"
                  className="rounded-2xl shadow-2xl w-full"
                />
              </div>
            </div>
          </div>

          {/* Pricing Section - Exact Layout */}
          <div className="mb-32">
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              <div className="relative">
                <div className="bg-gradient-to-br from-blue-900/20 to-purple-900/20 rounded-2xl p-8">
                  <h3 className="text-2xl font-bold text-white mb-6 text-center">
                    Choose Your Plan
                  </h3>

                  <div className="grid grid-cols-3 gap-4">
                    {/* Hobby Plan */}
                    <div className="bg-gray-900/50 border border-gray-700 rounded-xl p-4 text-center">
                      <div className="text-sm font-medium text-blue-400 mb-2">
                        Hobby
                      </div>
                      <div className="text-2xl font-bold text-white mb-1">
                        $0
                      </div>
                      <div className="text-xs text-gray-400 mb-4">
                        per month
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        className="w-full text-xs border-gray-600 text-gray-300"
                      >
                        Get started
                      </Button>
                    </div>

                    {/* Team Plan - Highlighted */}
                    <div className="bg-gradient-to-b from-purple-900/40 to-blue-900/40 border border-purple-500 rounded-xl p-4 text-center relative">
                      <div className="text-sm font-medium text-purple-400 mb-2">
                        Team
                      </div>
                      <div className="text-2xl font-bold text-white mb-1">
                        $29
                      </div>
                      <div className="text-xs text-gray-400 mb-4">
                        per month
                      </div>
                      <Button
                        size="sm"
                        className="w-full text-xs bg-purple-600 hover:bg-purple-700"
                      >
                        Get started
                      </Button>
                    </div>

                    {/* Enterprise Plan */}
                    <div className="bg-gray-900/50 border border-gray-700 rounded-xl p-4 text-center">
                      <div className="text-sm font-medium text-green-400 mb-2">
                        Enterprise
                      </div>
                      <div className="text-2xl font-bold text-white mb-1">
                        Custom
                      </div>
                      <div className="text-xs text-gray-400 mb-4">pricing</div>
                      <Button
                        size="sm"
                        variant="outline"
                        className="w-full text-xs border-gray-600 text-gray-300"
                      >
                        Contact us
                      </Button>
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-6">
                <h3 className="text-3xl font-bold text-white">
                  Visually edit anything
                </h3>
                <ul className="space-y-4">
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Modify any generated experience
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Drag and drop your components
                    </span>
                  </li>
                  <li className="flex items-start space-x-3">
                    <div className="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center mt-0.5">
                      <Check className="h-3 w-3 text-white" />
                    </div>
                    <span className="text-gray-300 text-base">
                      Fine-tune the styling of any element with full precision
                      control
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Additional Developer Experience Section */}
          <div className="mb-32">
            <div className="text-center mb-16">
              <div className="inline-flex items-center bg-green-900/30 border border-green-700/50 rounded-full px-4 py-1.5 mb-6">
                <span className="text-xs font-medium text-green-400 uppercase tracking-wider">
                  DEVELOPER EXPERIENCE
                </span>
              </div>
              <h2 className="text-4xl md:text-5xl font-bold mb-6 leading-tight text-white">
                Ship faster with your existing stack
              </h2>
              <p className="text-lg text-gray-400 max-w-3xl mx-auto leading-relaxed">
                Integrate seamlessly with your current development workflow and
                tools
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-gray-900/50 border border-gray-700 rounded-2xl p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl mx-auto mb-6 flex items-center justify-center">
                  <Code className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white mb-4">
                  Clean Code Output
                </h3>
                <p className="text-gray-400 text-sm leading-relaxed">
                  Generated code follows your team's standards and best
                  practices. No cleanup required.
                </p>
              </div>

              <div className="bg-gray-900/50 border border-gray-700 rounded-2xl p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-blue-500 rounded-xl mx-auto mb-6 flex items-center justify-center">
                  <Zap className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white mb-4">
                  Lightning Fast
                </h3>
                <p className="text-gray-400 text-sm leading-relaxed">
                  Generate production-ready components in seconds, not hours or
                  days.
                </p>
              </div>

              <div className="bg-gray-900/50 border border-gray-700 rounded-2xl p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl mx-auto mb-6 flex items-center justify-center">
                  <Globe className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white mb-4">
                  Universal Compatibility
                </h3>
                <p className="text-gray-400 text-sm leading-relaxed">
                  Works with React, Vue, Angular, Svelte, and any modern web
                  framework.
                </p>
              </div>
            </div>
          </div>

          {/* Enterprise Features Section */}
          <div className="mb-32">
            <div className="text-center mb-16">
              <div className="inline-flex items-center bg-orange-900/30 border border-orange-700/50 rounded-full px-4 py-1.5 mb-6">
                <span className="text-xs font-medium text-orange-400 uppercase tracking-wider">
                  ENTERPRISE READY
                </span>
              </div>
              <h2 className="text-4xl md:text-5xl font-bold mb-6 leading-tight text-white">
                Built for scale and security
              </h2>
            </div>

            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div className="space-y-8">
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Users className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white mb-2">
                      Team Collaboration
                    </h3>
                    <p className="text-gray-400">
                      Real-time collaboration with your entire team. Share
                      designs, iterate together, and maintain consistency across
                      all projects.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-green-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Check className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white mb-2">
                      Enterprise Security
                    </h3>
                    <p className="text-gray-400">
                      SOC 2 compliant with advanced security features. Your code
                      and data stay completely private and secure.
                    </p>
                  </div>
                </div>

                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Zap className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white mb-2">
                      Custom Integrations
                    </h3>
                    <p className="text-gray-400">
                      Connect with your existing tools and workflows. API access
                      for custom integrations and automation.
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-2xl p-8 border border-gray-700">
                <h3 className="text-2xl font-bold text-white mb-6">
                  Ready to get started?
                </h3>
                <div className="space-y-4">
                  <Button className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white py-3 text-lg">
                    Start Free Trial
                  </Button>
                  <Button
                    variant="outline"
                    className="w-full border-gray-600 text-gray-300 hover:bg-gray-800 py-3 text-lg"
                  >
                    Schedule Demo
                  </Button>
                </div>
                <p className="text-xs text-gray-500 mt-4 text-center">
                  No credit card required • 14-day free trial • Cancel anytime
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer - Exact styling */}
      <footer className="border-t border-gray-800 py-12 px-6 bg-black">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <div className="w-6 h-6 bg-gradient-to-r from-blue-400 to-purple-500 rounded-sm flex items-center justify-center">
                  <span className="text-white font-bold text-xs">◆</span>
                </div>
                <span className="text-lg font-medium text-white">
                  builder.io
                </span>
              </div>
              <p className="text-gray-400 text-sm">
                The complete platform for building with code
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-white text-sm">Product</h4>
              <ul className="space-y-2 text-sm text-gray-400">
                <li>
                  <a href="#" className="hover:text-white">
                    Features
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Pricing
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Documentation
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-white text-sm">Company</h4>
              <ul className="space-y-2 text-sm text-gray-400">
                <li>
                  <a href="#" className="hover:text-white">
                    About
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Blog
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Careers
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-white text-sm">
                Resources
              </h4>
              <ul className="space-y-2 text-sm text-gray-400">
                <li>
                  <a href="#" className="hover:text-white">
                    Help Center
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Community
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-white">
                    Contact
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
            © 2024 Builder.io. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  );
}
